require 'spec_helper'

describe Spree::Gateway::Beanstream do
  let(:gateway) { described_class.create!(name: 'Beanstream') }

  context '.provider_class' do
    it 'is a Beanstream gateway' do
      expect(gateway.provider_class).to eq ::ActiveMerchant::Billing::BeanstreamGateway
    end
  end

  context '.payment_profiles_supported?' do
    it 'return true' do
      expect(gateway.payment_profiles_supported?).to be true
    end
  end
end