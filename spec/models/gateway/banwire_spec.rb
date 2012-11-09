require 'spec_helper'

describe Spree::Gateway::Banwire do
  let(:gateway) { Spree::Gateway::Banwire.create!(:name => "Banwire") }

  it "should be Banwire gateway" do
    gateway.provider_class.should == ::ActiveMerchant::Billing::BanwireGateway
  end
end
