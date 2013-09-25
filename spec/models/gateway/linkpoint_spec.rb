require 'spec_helper'

describe Spree::Gateway::Linkpoint do
  let(:gateway) { Spree::Gateway::Linkpoint.create!(:name => "Linkpoint") }
  let(:provider) { double('provider') }
  let(:money) { double('money') }
  let(:credit_card) { double('credit_card') }
  let(:identification) { double('identification') }
  let(:options) { { subtotal: 3, discount: -1 } }

  before do
    gateway.provider_class.stub(new: provider)
  end

  it "should be Linkpoint gateway" do
    gateway.provider_class.should == ::ActiveMerchant::Billing::LinkpointGateway
  end

  describe "#authorize" do
    it "adds the discount to the subtotal" do
      provider.should_receive(:authorize)
        .with(money, credit_card, subtotal: 2, discount: 0)
      gateway.authorize(money, credit_card, options)
    end
  end

  describe "#purchase" do
    it "adds the discount to the subtotal" do
      provider.should_receive(:purchase)
        .with(money, credit_card, subtotal: 2, discount: 0)
      gateway.purchase(money, credit_card, options)
    end
  end

  describe "#capture" do
    let(:authorization) { double('authorization') }

    it "adds the discount to the subtotal" do
      provider.should_receive(:capture)
        .with(money, authorization, subtotal: 2, discount: 0)
      gateway.capture(money, authorization, options)
    end
  end

  describe "#void" do
    it "adds the discount to the subtotal" do
      provider.should_receive(:void)
        .with(identification, subtotal: 2, discount: 0)
      gateway.void(identification, options)
    end
  end

  describe "#credit" do
    it "adds the discount to the subtotal" do
      provider.should_receive(:credit)
        .with(money, identification, subtotal: 2, discount: 0)
      gateway.credit(money, identification, options)
    end
  end
end
