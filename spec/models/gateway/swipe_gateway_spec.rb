require 'spec_helper'

describe Spree::Gateway::SwipeGateway do

  before(:each) do
    Spree::Gateway.update_all :active => false
    @gateway = Spree::Gateway::SwipeGateway.create!(:name => "Swipe Gateway", :environment => "sandbox", :active => true)

    @gateway.set_preference(:login, "2077103073D8B5")
    @gateway.set_preference(:api_key, "f2fe4efd5033edfaed9e4aad319ef4d34536a10eea07f90f182616d7216ae2b8")
    @gateway.set_preference(:region, "NZ")
    @gateway.save!

    @country = FactoryGirl.create(:country, :name => "New Zealand", :iso_name => "New Zealand", :iso3 => "NZD", :iso => "NZ", :numcode => 61)
    @state   = FactoryGirl.create(:state, :name => "Canterbury", :abbr => "CAN", :country => @country)
    @address = FactoryGirl.create(:address,
      :firstname => 'Ronald C',
      :lastname => 'Robot',
      :address1 => '1234 My Street',
      :address2 => 'Apt 1',
      :city =>  'Christchurch',
      :zipcode => '8000',
      :phone => '88888888',
      :state => @state,
      :country => @country
    )
    @order = FactoryGirl.create(:order_with_totals, :bill_address => @address, :ship_address => @address)
    @order.update!
    @credit_card = FactoryGirl.create(:credit_card, 
      :verification_value => '123',
      :number => '1234123412341234',
      :cc_type => :visa,
      :month => 5,
      :year => Time.now.year + 1,
      :first_name => 'Ronald C',
      :last_name => 'Robot'
    )
    @payment = FactoryGirl.create(:payment, 
      :source => @credit_card,
      :order => @order,
      :payment_method => @gateway, :amount => 10.00)
    @payment.payment_method.environment = "test"


  end

  it "can purchase" do
    @payment.purchase!
    @payment.state.should == 'completed'
  end
end