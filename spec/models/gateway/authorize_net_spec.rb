require 'spec_helper'

describe Spree::Gateway::AuthorizeNet do
  let (:gateway) { described_class.create!(name: 'Authorize.net') }

  context '.provider_class' do
    it 'is a AuthorizeNet gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::AuthorizeNetGateway
    end
  end

  describe 'options' do
    it 'include :test => true when :test_mode is true' do
      gateway.preferred_test_mode = true
      expect(gateway.options[:test]).to be true
    end

    it 'does not include :test when test_mode is false' do
      gateway.preferred_test_mode = false
      expect(gateway.options[:test]).to be false
    end
  end
end
