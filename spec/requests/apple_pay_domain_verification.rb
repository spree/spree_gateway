require 'spec_helper'

describe 'Apple Pay Domain Verification', type: :request do
  let(:domain_verification_certificate) { FFaker::Lorem.characters(20) }
  let(:stripe_apple_pay_payment_method) do
    Spree::Gateway::StripeApplePayGateway.create!(
      name: 'ApplePay',
      preferred_domain_verification_certificate: domain_verification_certificate
    )
  end
  let(:execute) { get '/.well-known/apple-developer-merchantid-domain-association' }

  shared_examples 'returns 404' do
    it 'returns RecordNotFound exception' do
      expect { execute }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context 'apple pay gateway exists' do
    before do
      stripe_apple_pay_payment_method
      execute
    end

    it 'returns 200 HTTP status' do
      expect(response.status).to eq(200)
    end

    it 'renders domain verification certificate' do
      expect(response.body).to eq domain_verification_certificate
    end
  end

  context 'apple pay gateway doesnt exist' do
    it_behaves_like 'returns 404'
  end

  context 'apple pay gateway not active' do
    before do
      stripe_apple_pay_payment_method.update_column(:active, false)
    end

    it_behaves_like 'returns 404'
  end
end
