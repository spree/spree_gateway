require 'spec_helper'

describe 'Api V2 Storefront Intents Spec', type: :request do
  let!(:store) { Spree::Store.default }
  let(:currency) { store.default_currency }
  let(:user)  { create(:user) }
  let(:order) { create(:order, user: user, store: store, currency: currency) }
  let(:params) { {} }

  include_context 'API v2 tokens'

  describe '#payment_confirmation_data' do
    subject :post_payment_confirmation_data do
      post '/api/v2/storefront/intents/payment_confirmation_data', headers: headers, params: params
    end

    include_context 'API v2 tokens'

    context 'when user is authorized' do
      let(:headers) { headers_bearer.merge(headers_order_token) }

      context 'when current order has payment intent' do
        let(:secret_key) { 'key' }
        let(:provider) do
          double('provider').tap do |p|
            p.stub(:purchase)
            p.stub(:authorize)
            p.stub(:capture)
          end
        end
        let(:gateway) do
          gateway = Spree::Gateway::StripeElementsGateway.new(active: true)
          gateway.set_preference :secret_key, secret_key
          gateway.set_preference :intents, 'true'
          gateway.name = 'Stripe Elements'
          gateway.stores << order.store
          allow(gateway).to receive(:options_for_purchase_or_auth).and_return ['money','cc','opts']
          allow(gateway).to receive_messages provider: provider
          allow(gateway).to receive_messages source_required: true
          allow(gateway).to receive_messages create_profile: true
          gateway
        end
        let!(:payment) do
          create(:payment,
                 source: create(:credit_card),
                 order: order, payment_method: gateway,
                 state: 'pending',
                 intent_client_key: intent_client_key)
        end

        before { post_payment_confirmation_data }

        context 'when last valid payment has intent client key' do
          let(:intent_client_key) { 'intent_client_key' }

          it_behaves_like 'returns 200 HTTP status'
        end

        context 'when last valid payment does not have intent client key' do
          let(:intent_client_key) { nil }

          it_behaves_like 'returns 422 HTTP status'

          it 'includes valid response message' do
            expect(response.body).to include I18n.t('spree.no_payment_authorization_needed')
          end
        end

        context 'when current order has completed payments' do
          let(:order) { create(:order_ready_to_ship, user: user, store: store, currency: currency) }
          let(:intent_client_key) { 'intent_client_key' }

          it_behaves_like 'returns 403 HTTP status'
        end
      end

      context 'when current order does not have payment intent' do
        before { post_payment_confirmation_data }

        it_behaves_like 'returns 422 HTTP status'

        it 'includes valid response message' do
          expect(response.body).to include I18n.t('spree.no_payment_authorization_needed')
        end
      end
    end

    context 'when some authorization data is missing' do
      let(:headers) { {} }

      before { post_payment_confirmation_data }

      it_behaves_like 'returns 403 HTTP status'
    end
  end
end
