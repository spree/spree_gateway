require 'spec_helper'

describe Spree::Gateway::Worldpay do
  let(:gateway) { described_class.create!(name: 'Worldpay', stores: [::Spree::Store.default]) }

  context '.provider_class' do
    it 'is a Worldpay gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::WorldpayGateway
    end
  end
end
