require 'spec_helper'

describe Spree::Gateway::StripeGateway::ApplePayGateway do
  let(:gateway) { Spree::Gateway::StripeGateway::ApplePayGateway.new }

  describe 'inheritance' do
    it 'is expected to inherit from class StripeGateway' do
      expect(described_class).to be < Spree::Gateway::StripeGateway
    end
  end

  describe '#method_type' do
    it 'is expected to return applepay' do
      expect(gateway.method_type).to eq('applepay')
    end
  end
end
