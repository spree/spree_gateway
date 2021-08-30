require 'spec_helper'

describe Spree::Gateway::Quickpay do
  let(:gateway) { described_class.create!(name: 'QuickpayGateway', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a Quickpay gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::QuickpayV10Gateway
    end
  end
end
