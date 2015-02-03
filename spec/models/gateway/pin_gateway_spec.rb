require 'spec_helper'

describe Spree::Gateway::PinGateway do

  before do
    Spree::Gateway.update_all(active: false)
    @gateway = described_class.create!(name: 'Pin Gateway', active: true)
    @gateway.set_preference(:api_key, 'W_VzkRCZSILiKWUS-dndUg')
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

    order = create(:order_with_totals, bill_address: address, ship_address: address)
    order.update!

    credit_card = create(:credit_card,
      verification_value: '123',
      number:             '5520000000000000',
      month:              5,
      year:               Time.now.year + 1,
      name:               'Ronald C Robot',
      cc_type:            'mastercard'
    )

    @payment = create(:payment, source: credit_card, order: order, payment_method: @gateway, amount: 10.00)
  end

  it 'can purchase' do
    @payment.purchase!
    expect(@payment.state).to eq 'completed'
  end

  # Regression test for #106
  it 'uses auto capturing' do
    expect(@gateway.auto_capture?).to be true
  end

  it 'always uses purchase' do
    @payment.should_receive(:purchase!)
    @payment.process!
  end
end
