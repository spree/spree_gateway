require 'spec_helper'

describe Spree::Gateway::PayPalGateway do
  let(:gateway) { described_class.create!(name: 'PayPal') }

  context '.provider_class' do
    it 'is a PayPal gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::PaypalGateway
    end
  end
end