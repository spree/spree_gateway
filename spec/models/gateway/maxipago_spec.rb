require 'spec_helper'

describe Spree::Gateway::Maxipago do
  let(:gateway) { described_class.create!(name: 'Maxipago') }

  context '.provider_class' do
    it 'is a Maxipago gateway' do
      expect(subject.provider_class).to eq ::ActiveMerchant::Billing::MaxipagoGateway
    end
  end

  context '.auto_capture?' do
    it 'return true' do
      expect(subject.auto_capture?).to be true
    end
  end
end