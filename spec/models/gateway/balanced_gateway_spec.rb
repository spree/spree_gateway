require 'spec_helper'

describe Spree::Gateway::BalancedGateway do
  let(:gateway) { Spree::Gateway::BalancedGateway.create!(:name => "Balanced") }

  it "should be Balanced gateway" do
    gateway.provider_class.should == ::ActiveMerchant::Billing::BalancedGateway
  end
end
