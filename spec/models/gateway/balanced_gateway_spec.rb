require 'spec_helper'

describe Spree::Gateway::BalancedGateway do
  let(:gateway) { described_class.create!(name: 'Balanced', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a Balanced gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::BalancedGateway
    end
  end

  context '.payment_profiles_supported?' do
    it 'return true' do
      expect(gateway.payment_profiles_supported?).to be true
    end
  end
end
