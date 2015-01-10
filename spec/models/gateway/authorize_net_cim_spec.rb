require 'spec_helper'

describe Spree::Gateway::AuthorizeNetCim do
  let (:gateway) { described_class.new }

  context '.provider_class' do
    it 'is a AuthorizeNetCim gateway' do
      expect(gateway.provider_class).to eq ::Spree::Gateway::AuthorizeNetCim
    end
  end

  context '.payment_profiles_supported?' do
    it 'return true' do
      expect(subject.payment_profiles_supported?).to be true
    end
  end

  describe 'options' do
    it 'include :test => true when test server is "test"' do
      gateway.preferred_server = "test"
      expect(gateway.options[:test]).to be true
    end

    it 'does not include :test when test server is "live"' do
      gateway.preferred_server = "live"
      expect(gateway.options[:test]).to be_nil
    end
  end
end
