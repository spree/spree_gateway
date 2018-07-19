require 'spec_helper'

describe Spree::ApplePayDomainVerificationController do
  let(:domain_verification_certificate) { FFaker::Lorem.characters(20) }
  let!(:stripe_apple_pay_payment_method) do
    Spree::Gateway::StripeApplePayGateway.create!(
      name: 'ApplePay',
      preferred_domain_verification_certificate: domain_verification_certificate
    )
  end

  context '#show' do
    it 'renders domain verification certificate' do
      get :show
      expect(response.body).to eq domain_verification_certificate
    end
  end
end
