require 'spec_helper'

describe Spree::Gateway::EwayRapid do
  let(:gateway) { described_class.create!(name: 'eWAY Rapid', stores: [::Spree::Store.default]) }

  describe '#provider_class' do
    it 'should be an eWAY Rapid gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::EwayRapidGateway
    end
  end

  describe '#options' do
    it 'should flag test option if preferred_test_mode is true' do
      gateway.preferred_test_mode = true
      expect(gateway.options[:test]).to be true
    end

    it 'should unflag test option if preferred_test_mode is false' do
      gateway.preferred_test_mode = false
      expect(gateway.options[:test]).to be false
    end
  end
end
