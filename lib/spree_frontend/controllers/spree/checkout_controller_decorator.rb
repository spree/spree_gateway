module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :process_payments_and_set_keys, only: :edit, if: proc { params[:state] == 'payment_confirm' }
    end

    def process_payments_and_set_keys
      @order.tap do |order|
        order.process_payments!
        order.reload.payments.valid.where.not(intent_client_key: nil).last.tap do |payment|
          @client_secret = payment.intent_client_key
          @pk_key = payment.payment_method.preferred_publishable_key
        end
      end
    end
  end
end

::Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
