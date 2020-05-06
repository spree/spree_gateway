module Spree
  module Api
    module V1
      module Stripe
        class IntentsController < ::ActionController::API
          def handle_response
            @order = Spree::Order.incomplete.find_by!(token: params['order_token'])
            if params['response']['error']
              invalidate_payment
              render json: { errors: params['response']['error']['message'] }, status: 422
            else
              render json: { result: 'ok' }
            end
          end

          private

          def invalidate_payment
            payment = @order.payments.find_by!(response_code: params['response']['error']['payment_intent']['id'])
            payment.update(state: 'failed', intent_client_key: nil)
          end
        end
      end
    end
  end
end
