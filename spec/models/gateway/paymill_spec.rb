require 'spec_helper'

describe Spree::Gateway::Paymill do
  let(:gateway) { described_class.create!(name: 'Paymill') }

  context '.provider_class' do
    it 'is a Paymill gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::PaymillGateway
    end
  end
end
