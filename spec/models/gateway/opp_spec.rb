require 'spec_helper'

describe Spree::Gateway::OPP do
  let(:gateway) { described_class.create!(name: 'OPP') }

  context '.provider_class' do
    it 'is a OPP gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::OppGateway
    end
  end
end
