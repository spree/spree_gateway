require 'spec_helper'

describe Spree::Gateway::SecurePayAU do
  let(:gateway) { described_class.create!(name: 'SecurePayAU', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a SecurePayAU gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::SecurePayAuGateway
    end
  end
end
