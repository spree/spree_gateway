module Spree
  module Api
    module V1
      module Stripe
        class IntentsController < ::ActionController::API
          def handle_response
            if params['response']['error']
              invalidate_payment
              render json: { errors: params['response']['error']['message'] }, status: 422
            else
              render json: { message: 'The payment was successfully authorized.' }, status: :ok
            end
          end

          private

          def invalidate_payment
            @order = Spree::Order.complete.find(params['order_id'])
            payment = @order.payments.find_by!(response_code: params['response']['error']['payment_intent']['id'])
            payment.update(state: 'failed', intent_client_key: nil)
          end
        end
      end
    end
  end
end
