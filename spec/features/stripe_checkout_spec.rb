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
    fill_in_card_code_and_expiry("123", "01 / #{Time.now.year + 1}")
    click_button "Save and Continue"
    expect(page.current_url).to include("/checkout/confirm")
    click_button "Place Order"
    check_message_or_current_path
  end

  # This will fetch a token from Stripe.com and then pass that to the webserver.
  # The server then processes the payment using that token.
  it "can process a valid payment (with JS)", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    # Otherwise ccType field does not get updated correctly
    page.execute_script("$('.cardNumber').trigger('change')")
    fill_in_card_code_and_expiry("123", "01 / #{Time.now.year + 1}")
    click_button "Save and Continue"
    # Wait for Stripe API to return + form to submit
    wait_for_stripe if Spree.version.to_f <= 4.0
    expect(page).to have_css('#checkout_form_confirm')
    expect(page.current_url).to include("/checkout/confirm")
    click_button "Place Order"
    check_message_or_current_path
  end

  it "shows an error with an invalid credit card number", :js => true do
    # Card number is NOT valid. Fails Luhn checksum
    fill_in "Card Number", :with => "4242 4242 4242 4249"
    click_button "Save and Continue"
    wait_for_stripe if Spree.version.to_f <= 4.0
    check_error_messages("Your card number is incorrect")
  end

  it "shows an error with invalid security fields", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in_card_code_and_expiry("99", "01 / #{Time.now.year + 1}")
    click_button "Save and Continue"
    wait_for_stripe if Spree.version.to_f <= 4.0
    check_error_messages("Your card's security code is invalid.")
  end

  it "shows an error with invalid expiry month field", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in_card_code_and_expiry("123", "00 / #{Time.now.year + 1}")
    click_button "Save and Continue"
    wait_for_stripe if Spree.version.to_f <= 4.0
    check_error_messages("Your card's expiration month is invalid.")
  end

  it "shows an error with invalid expiry year field", :js => true do
    fill_in "Card Number", :with => "4242 4242 4242 4242"
    fill_in_card_code_and_expiry("123", "12 / ")
    click_button "Save and Continue"
    wait_for_stripe  if Spree.version.to_f <= 4.0
    check_error_messages("Your card's expiration year is invalid.")
  end

  def fill_in_card_code_and_expiry(card_code, card_expiry)
    if Spree.version.to_f <= 4.0
      fill_in "Card Code", :with => card_code
      fill_in "Expiration", :with => card_expiry
    else
      fill_in "card_code", :with => card_code
      fill_in "card_expiry", :with => card_expiry
    end
  end

  def check_message_or_current_path
    if Spree.version.to_f <= 4.0
      expect(page).to have_content("Your order has been processed successfully")
    else
      expect(page).to have_current_path(spree.root_path)
    end
  end

  def check_error_messages(message)
    if Spree.version.to_f <= 4.0
      expect(page).to have_content(message)
    else
      expect(page).to have_content(message)
    end
  end
end
