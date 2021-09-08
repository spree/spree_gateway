module Spree
  module Api
    module V2
      module Storefront
        class IntentsController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2::Storefront::OrderConcern

          def payment_confirmation_data
            spree_authorize! :update, spree_current_order, order_token

            if spree_current_order.intents?
              spree_current_order.process_payments!
              spree_current_order.reload
              last_valid_payment = spree_current_order.payments.valid.where.not(intent_client_key: nil).last

              if last_valid_payment.present?
                client_secret = last_valid_payment.intent_client_key
                publishable_key = last_valid_payment.payment_method&.preferred_publishable_key
                return render json: { client_secret: client_secret, pk_key: publishable_key }, status: :ok
              end
            end

            render_error_payload(I18n.t('spree.no_payment_authorization_needed'))
          end

          def handle_response
            if params['response']['error']
              invalidate_payment
              render_error_payload(params['response']['error']['message'])
            else
              render_serialized_payload { { message: I18n.t('spree.payment_successfully_authorized') } }
            end
          end

          private

          def invalidate_payment
            payment = spree_current_order.payments.find_by!(response_code: params['response']['error']['payment_intent']['id'])
            payment.update(state: 'failed', intent_client_key: nil)
          end
        end
      end
    end
  end
end
