module Spree
  module Stripe
    class IntentsController < ::ActionController::API
      def handle_response
        @order = Spree::Order.find_by!(token: params['token'])
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
