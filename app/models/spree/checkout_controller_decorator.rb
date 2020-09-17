module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :process_payments_and_set_keys, only: :edit, if: proc { params[:state] == 'payment_confirm' }
    end

    def process_payments_and_set_keys
      @order.process_payments!

      intent_secrets = @order.payments.valid.map do |payment|
        next unless payment.intent_client_key

        {
          intent_key: payment.intent_client_key,
          pk_key: payment.payment_method.preferred_publishable_key
        }
      end.last
      @client_secret = intent_secrets.try(:[], :intent_key)
      @pk_key = intent_secrets.try(:[], :pk_key)
    end
  end
end

if ::Spree::CheckoutController.included_modules.exclude?(Spree::CheckoutControllerDecorator)
  ::Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
end
