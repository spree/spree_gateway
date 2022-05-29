module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :process_payments_and_set_keys, only: :edit, if: proc { params[:state] == 'payment_confirm' }
    end

    def process_payments_and_set_keys
      @order.tap do |order|
        @client_secret = nil
        @pk_key = nil

        order.process_payments!
        last_valid_payment = order.reload.payments.valid.where.not(intent_client_key: nil).last

        if last_valid_payment
          @client_secret = last_valid_payment.intent_client_key
          @pk_key = last_valid_payment.payment_method.preferred_publishable_key
        end
      end
    end
  end
end

::Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
