require 'spec_helper'

describe 'Apple Domain Verification', type: :request do
  let(:domain_verification_certificate) { FFaker::Lorem.characters(20) }
  let!(:stripe_apple_pay_payment_method) do
    Spree::Gateway::StripeApplePayGateway.create!(
      name: 'ApplePay',
      preferred_domain_verification_certificate: domain_verification_certificate
    )
  end

  before { get '/.well-known/apple-developer-merchantid-domain-association' }

  it 'returns 200 HTTP status' do
    expect(response.status).to eq(200)
  end

  it 'renders domain verification certificate' do
    expect(response.body).to eq domain_verification_certificate
  end
end
