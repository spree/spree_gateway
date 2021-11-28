require 'spec_helper'

describe 'Api V2 Storefront Intents Spec', type: :request do
  let!(:store) { Spree::Store.default }
  let(:currency) { store.default_currency }
  let(:user)  { create(:user) }
  let(:order) { create(:order, user: user, store: store, currency: currency) }

  include_context 'API v2 tokens'

  describe '#payment_confirmation_data' do
    subject :post_payment_confirmation_data do
      post '/api/v2/storefront/intents/payment_confirmation_data', headers: headers, params: params
    end

    include_context 'API v2 tokens'

    context 'when user is authorized' do
      let(:params) { {} }
      let(:headers) { headers_bearer.merge(headers_order_token) }

      context 'when current order has payment intent' do
        let(:provider) do
          double('provider').tap do |p|
            p.stub(:purchase)
            p.stub(:authorize)
            p.stub(:capture)
          end
        end
        let(:gateway) do
          gateway = Spree::Gateway::StripeElementsGateway.new(active: true)
          gateway.set_preference :secret_key, 'secret_key'
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
                 order: order,
                 payment_method: gateway,
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
      let(:params) { {} }
      let(:headers) { {} }

      before { post_payment_confirmation_data }

      it_behaves_like 'returns 403 HTTP status'
    end
  end

  describe '#handle_response' do
    subject :post_handle_response do
      post '/api/v2/storefront/intents/handle_response', headers: headers, params: params
    end

    let(:headers) { headers_bearer.merge(headers_order_token) }
    let(:provider) do
      double('provider').tap do |p|
        p.stub(:purchase)
        p.stub(:authorize)
        p.stub(:capture)
      end
    end
    let(:gateway) do
      gateway = Spree::Gateway::StripeElementsGateway.new(active: true)
      gateway.set_preference :secret_key, 'secret_key'
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
             order: order,
             payment_method: gateway,
             state: 'pending',
             intent_client_key: 'intent_client_key')
    end

    include_context 'API v2 tokens'

    context 'when response param does not include errors' do
      let(:params) do
        {
          response: {
            message: 'everything is ok'
          }
        }
      end

      before { post_handle_response }

      it_behaves_like 'returns 200 HTTP status'

      it 'includes valid response message' do
        expect(response.body).to include I18n.t('spree.payment_successfully_authorized')
      end

      it 'does not update payment' do
        expect { post_handle_response }.not_to change { payment }
      end
    end

    context 'when response param includes errors' do
      let(:payment_response_code) { payment.response_code }
      let(:params) do
        {
          response: {
            error: {
              payment_intent: {
                id: payment_response_code
              },
              message: 'something went wrong'
            }
          }
        }
      end

      before { post_handle_response }

      it_behaves_like 'returns 422 HTTP status'

      context 'when payment to invalidate is found' do
        it 'changes payment state to failed' do
          expect(payment.state).not_to eq 'failed'
          expect(payment.reload.state).to eq 'failed'
        end

        it 'clears payment intent_client_key' do
          expect(payment.intent_client_key).not_to be nil
          expect(payment.reload.intent_client_key).to be nil
        end

        it 'includes valid response message' do
          expect(response.body).to include params[:response][:error][:message]
        end
      end

      context 'when payment to invalidate is not found' do
        let(:payment_response_code) { 'unexisting response code' }

        it_behaves_like 'returns 404 HTTP status'
      end
    end
  end
end
