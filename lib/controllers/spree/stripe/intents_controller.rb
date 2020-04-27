module Spree
  module Stripe
    class IntentsController < ::ActionController::Base
      def handle_response
        @order = Spree::Order.find_by!(number: params['order'])
        if params['response']['error']
          invalidate_payment
          flash[:error] = 'cannot verify payment'
          redirect_to order_path(@order)
        end
      end

      private

      def invalidate_payment
        payment = Spree::Payment.find_by!(response_code: params['response']['error']['payment_intent']['id'])
        payment.update(state: 'failed', intent_client_key: nil)
      end
    end
  end
end
