module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :set_keys, only: :edit, if: proc { params[:state] == 'payment_confirm' }
    end

    def set_keys
      @order.process_payments!

      # Temporary workaround.
      # Without it order cannot be finished due to the wrong payment state updated after
      # executing `@order.process_payments!`, which is used to retrieve `intent_client_key`.
      @order.payments.update_all(state: 'checkout')

      intent_secrets = @order.payments.valid.map do |payment|
        next unless payment.intent_client_key

        {
          intent_key: payment.intent_client_key,
          pk_key: payment.payment_method.preferred_publishable_key
        }
      end.last
      @client_secret = intent_secrets[:intent_key]
      @pk_key = intent_secrets[:pk_key]
    end
  end
end

if ::Spree::CheckoutController.included_modules.exclude?(Spree::CheckoutControllerDecorator)
  ::Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
end
