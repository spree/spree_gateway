require 'spec_helper'

describe "Stripe checkout", type: :feature, js: true do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:stripe_payment_method) do
    Spree::Gateway::StripeGateway.create!(
      name: 'Stripe',
      preferred_secret_key: 'sk_test_VCZnDv3GLU15TRvn8i2EsaAN',
      preferred_publishable_key: 'pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg',
      stores: [::Spree::Store.default]
    )
  end

  let!(:zone) { create(:zone) }

  before do
    if Spree.version.to_f >= 4.2
      payment_method = Spree::PaymentMethod.first
      payment_method.update!(stores: [Spree::Store.first])
    end

    user = create(:user)

    order = OrderWalkthrough.up_to(:delivery)
    order.stub :confirmation_required? => true

    order.reload
    order.user = user
    order.update_with_updater!

    Spree::CheckoutController.any_instance.stub(:current_order => order)
    Spree::CheckoutController.any_instance.stub(:try_spree_current_user => user)
    Spree::CheckoutController.any_instance.stub(:skip_state_validation? => true)
    Spree::OrdersController.any_instance.stub(try_spree_current_user: user)

    # Capybara should wait up to 10 seconds for async. changes to be applied
    Capybara.default_max_wait_time = 10

    visit spree.checkout_state_path(:payment)
    begin
      setup_stripe_watcher
    rescue Capybara::NotSupportedByDriverError
    end
  end

  # This will pass the CC data to the server and the StripeGateway class handles it
  it "can process a valid payment (without JS)", js: false do
    fill_in 'card_number', with: '4242 4242 4242 4242'
    fill_in 'card_code', with: '123'
    fill_in 'card_expiry', with: "01 / #{Time.current.year + 1}"
    click_button "Save and Continue"
    expect(page.current_url).to include("/checkout/confirm")
    click_button "Place Order"
    order = Spree::Order.complete.last
    expect(page.current_url).to include("/orders/#{order.number}")
    expect(page).to have_content(order.number)
  end

  # This will fetch a token from Stripe.com and then pass that to the webserver.
  # The server then processes the payment using that token.
  it "can process a valid payment (with JS)" do
    fill_in_with_force('card_number', with: "4242424242424242")
    fill_in_with_force('card_expiry', with: "01 / #{Time.current.year + 1}")
    fill_in 'card_code', with: '123'
    click_button "Save and Continue"
    wait_for_stripe # Wait for Stripe API to return + form to submit
    expect(page).to have_css('#checkout_form_confirm')
    expect(page.current_url).to include("/checkout/confirm")
    click_button "Place Order"
    order = Spree::Order.complete.last
    expect(page.current_url).to include("/orders/#{order.number}")
    expect(page).to have_content(order.number)
  end

  it "shows an error with an invalid credit card number" do
    # Card number is NOT valid. Fails Luhn checksum
    fill_in 'card_number', with: '4242 4242 4242 4249'
    click_button "Save and Continue"
    wait_for_stripe
    if Spree.version.to_f >= 3.7 and Spree.version.to_f <= 4.1
      expect(page).to have_content("The card number is not a valid credit card number")
    end
    if Spree.version.to_f >= 4.2
      expect(page).to have_content("Your card number is incorrect")
      expect(page).to have_css('.has-error #card_number.error')
    end
  end

  it "shows an error with invalid security fields" do
    fill_in_with_force('card_number', with: "4242424242424242")
    fill_in_with_force('card_expiry', with: "01 / #{Time.current.year + 1}")
    fill_in 'card_code', with: '99'
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card's security code is invalid.")
    expect(page).to have_css('.has-error #card_code.error')
  end

  # this scenario will not occur on Spree 4.2 due to swapping jquery.payment to cleave
  # see https://github.com/spree/spree/pull/10363
  it "shows an error with invalid expiry month field" do
    skip if Spree.version.to_f >= 4.2
    fill_in_with_force('card_number', with: "4242424242424242")
    fill_in_with_force('card_expiry', with: "00 / #{Time.current.year + 1}")
    fill_in 'card_code', with: '123'
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card's expiration month is invalid.")
    expect(page).to have_css('.has-error #card_expiry.error')
  end

  it "shows an error with invalid expiry year field" do
    fill_in_with_force('card_number', with: "4242424242424242")
    fill_in_with_force('card_expiry', with: "12 / ")
    fill_in 'card_code', with: '123'
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card's expiration year is invalid.")
    expect(page).to have_css('.has-error #card_expiry.error')
  end
end

def fill_in_with_force(locator, with:)
  field_id = find_field(locator)[:id]
  page.execute_script("document.getElementById('#{field_id}').value = '#{with}';")
end
