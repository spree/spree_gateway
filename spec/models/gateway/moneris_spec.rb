require 'spec_helper'

describe Spree::Gateway::Moneris do
  let(:gateway) { described_class.create!(name: 'Moneris', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a Moneris gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::MonerisGateway
    end
  end
end