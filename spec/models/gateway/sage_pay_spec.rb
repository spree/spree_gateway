require 'spec_helper'

describe Spree::Gateway::SagePay do
  let(:gateway) { described_class.create!(name: 'SagePay', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a SagePay gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::SagePayGateway
    end
  end
end