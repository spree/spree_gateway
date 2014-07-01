require 'spec_helper'

describe Spree::Gateway::UsaEpay do
  before do
    Spree::Gateway.update_all(active: false)
    @gateway = Spree::Gateway::UsaEpay.create!(name: 'USA EPay Gateway', environment: 'sandbox', active: true)
    @gateway.set_preference(:login, '0r19zQBdp5nS8i3t4hFxz0di13yf56q1')
    @gateway.save!

    country = create(:country, name: 'United States', iso_name: 'UNITED STATES', iso3: 'USA', iso: 'US', numcode: 840)
    state = create(:state, name: 'Maryland', abbr: 'MD', country: country)
    address = create(:address,
      firstname: 'John',
      lastname:  'Doe',
      address1:  '1234 My Street',
      address2:  'Apt 1',
      city:      'Washington DC',
      zipcode:   '20123',
      phone:     '(555)555-5555',
      state:     state,
      country:   country)

    order = create(:order_with_totals, bill_address: address, ship_address: address)
    order.update!

    credit_card = create(:credit_card,
      verification_value: '123',
      number:             '4111111111111111',
      month:              9,
      year:               Time.now.year + 1,
      name:               'John Doe')

    @payment = create(:payment, source: credit_card, order: order, payment_method: @gateway, amount: 10.00)
    @payment.payment_method.environment = 'test'
  end

  context 'purchasing' do
    it 'can purchase a payment' do
      expect { @payment.purchase! }.to be_true
    end
  end

  context '.provider_class' do
    it 'is a Worldpay gateway' do
      expect(@gateway.provider_class).to eq ::ActiveMerchant::Billing::UsaEpayGateway
    end
  end
end