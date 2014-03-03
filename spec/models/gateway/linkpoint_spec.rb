require 'spec_helper'

describe Spree::Gateway::Linkpoint do
  let(:gateway) { described_class.create!(name: 'Linkpoint') }
  let(:provider) { double('provider') }
  let(:money) { double('money') }
  let(:credit_card) { double('credit_card') }
  let(:identification) { double('identification') }
  let(:options) { { subtotal: 3, discount: -1 } }

  before do
    gateway.provider_class.stub(new: provider)
  end

  context '.provider_class' do
    it 'is a Linkpoint gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::LinkpointGateway
    end
  end

  context '#authorize' do
    it 'adds the discount to the subtotal' do
      provider.should_receive(:authorize)
        .with(money, credit_card, subtotal: 2, discount: 0)
      gateway.authorize(money, credit_card, options)
    end
  end

  context '#purchase' do
    it 'adds the discount to the subtotal' do
      provider.should_receive(:purchase)
        .with(money, credit_card, subtotal: 2, discount: 0)
      gateway.purchase(money, credit_card, options)
    end
  end

  context '#capture' do
    let(:authorization) { double('authorization') }

    it 'adds the discount to the subtotal' do
      provider.should_receive(:capture)
        .with(money, authorization, subtotal: 2, discount: 0)
      gateway.capture(money, authorization, options)
    end
  end

  context '#void' do
    it 'adds the discount to the subtotal' do
      provider.should_receive(:void)
        .with(identification, subtotal: 2, discount: 0)
      gateway.void(identification, options)
    end
  end

  context '#credit' do
    it 'adds the discount to the subtotal' do
      provider.should_receive(:credit)
        .with(money, identification, subtotal: 2, discount: 0)
      gateway.credit(money, identification, options)
    end
  end
end
