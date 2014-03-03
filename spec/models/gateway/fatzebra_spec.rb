require 'spec_helper'

describe Spree::Gateway::Fatzebra do

  before do
    Spree::Gateway.update_all(active: false)
    @gateway = Spree::Gateway::Fatzebra.create!(name: 'Fat Zebra Gateway', environment: 'sandbox', active: true)
    @gateway.set_preference(:username, 'TEST')
    @gateway.set_preference(:token, 'TEST')
    @gateway.save!

    country = create(:country, name: 'Australia', iso_name: 'Australia', iso3: 'AUS', iso: 'AU', numcode: 61)
    state   = create(:state, name: 'Victoria', abbr: 'VIC', country: country)
    address = create(:address,
      firstname: 'Ronald C',
      lastname:  'Robot',
      address1:  '1234 My Street',
      address2:  'Apt 1',
      city:      'Melbourne',
      zipcode:   '3000',
      phone:     '88888888',
      state:     state,
      country:   country
    )

    order = create(:order_with_totals, bill_address: address, ship_address: address, last_ip_address: '127.0.0.1')
    order.update!

    credit_card = create(:credit_card,
      verification_value: '123',
      number:             '5123456789012346',
      month:              5,
      year:               Time.now.year + 1,
      name:               'Ronald C Robot'
    )

    @payment = create(:payment, source: credit_card, order: order, payment_method: @gateway, amount: 10.00)
    @payment.payment_method.environment = 'test'
  end

  it 'can purchase' do
    @payment.purchase!
    expect(@payment.state).to eq 'completed'
  end

  context '.auto_capture?' do
    it 'return true' do
      expect(@gateway.auto_capture?).to be_true
    end
  end
end
