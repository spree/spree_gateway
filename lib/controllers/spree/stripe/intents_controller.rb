module Spree
  module Stripe
    class IntentsController < ::ActionController::Base
      def handle_response
        @order = Spree::Order.find_by!(number: params['order'])
        if params['response']['error']
          invalidate_payment
          flash[:error] = params['response']['error']['message']
          redirect_to checkout_path
        else
          @order.next!
          if @order.completed?
            @current_order = nil
            flash['order_completed'] = true
            redirect_to(order_path(@order))
          else
            redirect_to(checkout_path)
          end
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
