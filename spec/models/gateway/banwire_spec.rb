require 'spec_helper'

describe Spree::Gateway::Banwire do
  let(:gateway) { described_class.create!(name: 'Banwire') }

  context '.provider_class' do
    it 'is a Banwire gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::BanwireGateway
    end
  end
end
