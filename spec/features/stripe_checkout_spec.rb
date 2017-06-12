require 'spec_helper'

describe "Stripe checkout", type: :feature do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:stripe_payment_method) do
    Spree::Gateway::StripeGateway.create!(
      :name => "Stripe",
      :preferred_secret_key => "sk_test_VCZnDv3GLU15TRvn8i2EsaAN",
      :preferred_publishable_key => "pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg"
    )
  end

  let!(:zone) { create(:zone) }

  before do
    user = create(:user)

    order = OrderWalkthrough.up_to(:delivery)
    order.stub :confirmation_required? => true

    order.reload
    order.user = user
    order.update_with_updater!

    Spree::CheckoutController.any_instance.stub(:current_order => order)
    Spree::CheckoutController.any_instance.stub(:try_spree_current_user => user)
    Spree::CheckoutController.any_instance.stub(:skip_state_validation? => true)

    # Capybara should wait up to 10 seconds for async. changes to be applied
    Capybara.default_max_wait_time = 10

    visit spree.checkout_state_path(:payment)
    begin
      setup_stripe_watcher
    rescue Capybara::NotSupportedByDriverError
    end
  end

  # This will pass the CC data to the server and the StripeGateway class handles it
  it "can process a valid payment (without JS)" do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in "Card Code", :with => "123"
    fill_in "Expiration", :with => "01 / #{Time.now.year + 1}"
    click_button "Save and Continue"
    expect(page.current_url).to include("/checkout/confirm")
    click_button "Place Order"
    expect(page).to have_content("Your order has been processed successfully")
  end

  # This will fetch a token from Stripe.com and then pass that to the webserver.
  # The server then processes the payment using that token.
  it "can process a valid payment (with JS)", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    # Otherwise ccType field does not get updated correctly
    page.execute_script("$('.cardNumber').trigger('change')")
    fill_in "Card Code", :with => "123"
    fill_in "Expiration", :with => "01 / #{Time.now.year + 1}"
    click_button "Save and Continue"
    wait_for_stripe # Wait for Stripe API to return + form to submit
    expect(page).to have_css('#checkout_form_confirm')
    expect(page.current_url).to include("/checkout/confirm")
    click_button "Place Order"
    expect(page).to have_content("Your order has been processed successfully")
  end

  it "shows an error with an invalid credit card number", :js => true do
    # Card number is NOT valid. Fails Luhn checksum
    fill_in "Card Number", :with => "4242 4242 4242 4249"
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card number is incorrect")
    expect(page).to have_css('.has-error #card_number.error')
  end

  it "shows an error with invalid security fields", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in "Expiration", :with => "01 / #{Time.now.year + 1}"
    fill_in "Card Code", :with => "99"
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card's security code is invalid.")
    expect(page).to have_css('.has-error #card_code.error')
  end

  it "shows an error with invalid expiry month field", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in "Expiration", :with => "00 / #{Time.now.year + 1}"
    fill_in "Card Code", :with => "123"
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card's expiration month is invalid.")
    expect(page).to have_css('.has-error #card_expiry.error')
  end

  it "shows an error with invalid expiry year field", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in "Expiration", :with => "12 / "
    fill_in "Card Code", :with => "123"
    click_button "Save and Continue"
    wait_for_stripe
    expect(page).to have_content("Your card's expiration year is invalid.")
    expect(page).to have_css('.has-error #card_expiry.error')
  end
end
