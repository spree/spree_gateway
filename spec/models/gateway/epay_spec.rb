require 'spec_helper'

describe Spree::Gateway::Epay do
  let(:gateway) { described_class.create!(name: 'Epay', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a Epay gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::EpayGateway
    end
  end
end
