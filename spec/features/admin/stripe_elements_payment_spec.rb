require 'spec_helper'

describe 'Admin Panel Stripe elements payment', type: :feature do
  stub_authorization!

  let!(:country) { create(:country, states_required: true) }
  let!(:state) { create(:state, country: country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, name: 'RoR Mug') }
  let!(:zone) { create(:zone) }
  let!(:stripe_elements_payment_method) do
    Spree::Gateway::StripeElementsGateway.create!(
        name: 'Stripe Element',
        preferred_secret_key: 'sk_test_VCZnDv3GLU15TRvn8i2EsaAN',
        preferred_publishable_key: 'pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg',
        stores: [::Spree::Store.default]
    )
  end

  let!(:order) { OrderWalkthrough.up_to(:payment) }
  before { visit spree.new_admin_order_payment_path(order.number) }

  it 'can process a valid payment' do
    fill_in_stripe_payment
    wait_for { !page.has_current_path?(spree.admin_order_payments_path(order.number)) }

    expect(page.body).to have_content('Payment has been successfully created!')
    expect(page).to have_current_path spree.admin_order_payments_path(order.number)
  end

  it 'shows an error with an invalid card name' do
    fill_in_stripe_payment(true)

    expect(page).to have_content("Credit card Name can't be blank")
    expect(page).to have_current_path spree.admin_order_payments_path(order.number)
  end

  it 'shows an error with an invalid card number' do
    fill_in_stripe_payment(false, true)

    expect(page).to have_content('The card number is not a valid credit card number.')
    expect(page).to have_current_path spree.new_admin_order_payment_path(order.number)
  end

  it 'shows an error with an invalid card code' do
    fill_in_stripe_payment(false, false, true)

    expect(page).to have_content("Your card's security code is invalid.")
    expect(page).to have_current_path spree.new_admin_order_payment_path(order.number)
  end

  it 'shows an error with an invalid card expiration' do
    fill_in_stripe_payment(false, false, false, true)

    if Spree.version.to_f >= 4.1 || Spree.version.to_f >= 3.7
      expect(page).to have_content('Credit card Month is not a number')
      expect(page).to have_content('Credit card Year is not a number')
      expect(page).to have_current_path spree.admin_order_payments_path(order.number)
    else
      expect(page).to have_content("Your card's expiration year is invalid.")
      expect(page).to have_current_path spree.new_admin_order_payment_path(order.number)
    end
  end

  def fill_in_stripe_payment(invalid_name = false, invalid_number = false, invalid_code = false, invalid_expiration = false)
    fill_in 'Name *', with: invalid_name ? '' : 'Stripe Elements Gateway Payment'
    fill_in_card_number(invalid_number)
    fill_in_cvc(invalid_code)
    fill_in_card_expiration(invalid_expiration)

    click_button 'Update'
  end

  def fill_in_card_number(invalid_number)
    number = invalid_number ? '123' : '4242 4242 4242 4242'
    fill_in_field('Card Number *', "#card_number#{stripe_elements_payment_method.id}", number)
  end

  def fill_in_card_expiration(invalid_expiration)
    valid_expiry = Spree.version.to_f >= 4.2 ? "01/#{Time.current.year + 1}" : "01 / #{Time.current.year + 1}"
    invalid_expiry = Spree.version.to_f >= 4.2 ? '01/' : '01 / '

    card_expiry = invalid_expiration ? invalid_expiry : valid_expiry
    fill_in_field('Expiration *', "#card_expiry#{stripe_elements_payment_method.id}", card_expiry)
  end

  def fill_in_cvc(invalid_code)
    value = invalid_code ? '1' : '123'
    label = Spree.version.to_f >= 4.2 ? 'Card Varification Code (CVC) *' : 'Card Code *'

    fill_in label, with: value
  end

  def fill_in_field(field_name, field_id, number)
    until page.find(field_id).value == number
      fill_in field_name, with: number
    end
  end
end
