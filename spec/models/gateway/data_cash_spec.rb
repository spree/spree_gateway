require 'spec_helper'

describe Spree::Gateway::DataCash do
  let(:gateway) { described_class.create!(name: 'DataCash', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a DataCash gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::DataCashGateway
    end
  end
end