require 'spec_helper'

describe Spree::Gateway::Eway do
  let(:gateway) { described_class.create!(name: 'Eway') }

  context '.provider_class' do
    it 'is a Eway gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::EwayGateway
    end
  end

  context '.auto_capture?' do
    it 'supports purchase method only' do
      expect(gateway.auto_capture?).to be_true
    end
  end

  describe 'options' do
    it 'include :test => true in  when :test_mode is true' do
      gateway.preferred_test_mode = true
      expect(gateway.options[:test]).to be_true
    end

    it 'does not include :test when test_mode is false' do
      gateway.preferred_test_mode = false
      expect(gateway.options[:test]).to be_false
    end
  end
end
