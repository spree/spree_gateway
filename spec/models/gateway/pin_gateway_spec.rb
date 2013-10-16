require 'spec_helper'

describe Spree::Gateway::PinGateway do

  before(:each) do
    Spree::Gateway.update_all :active => false
    @gateway = Spree::Gateway::PinGateway.create!(:name => "Pin Gateway", :environment => "sandbox", :active => true)

    @gateway.set_preference(:api_key, "W_VzkRCZSILiKWUS-dndUg" )
    @gateway.save!

    @country = FactoryGirl.create(:country, :name => "Australia", :iso_name => "Australia", :iso3 => "AUS", :iso => "AU", :numcode => 61)
    @state   = FactoryGirl.create(:state, :name => "Victoria", :abbr => "VIC", :country => @country)
    @address = FactoryGirl.create(:address,
      :firstname => 'Ronald C',
      :lastname => 'Robot',
      :address1 => '1234 My Street',
      :address2 => 'Apt 1',
      :city =>  'Melbourne',
      :zipcode => '3000',
      :phone => '88888888',
      :state => @state,
      :country => @country
    )
    @order = FactoryGirl.create(:order_with_totals, :bill_address => @address, :ship_address => @address)
    @order.update!
    @credit_card = FactoryGirl.create(:credit_card, 
      :verification_value => '123',
      :number => '5520000000000000',
      :month => 5,
      :year => Time.now.year + 1,
      :first_name => 'Ronald C',
      :last_name => 'Robot',
      :cc_type => 'mastercard'
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

  # Regression test for #106
  it "uses auto capturing" do
    expect(@gateway.auto_capture?).to be_true
  end

  it "always uses purchase" do
    @payment.should_receive(:purchase!)
    @payment.process!
  end
end