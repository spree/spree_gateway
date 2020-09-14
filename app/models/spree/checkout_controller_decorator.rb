module Spree
  module CheckoutControllerDecorator
    def self.prepended(base)
      base.before_action :set_keys, only: :edit, if: proc { params[:state] == 'payment_confirm' }
    end

    def set_keys
      @payment = @order.payments.valid.last
      create_payment_intent
      @client_secret = @payment_intent.params['client_secret']
      @pk_key = @payment.payment_method.preferred_publishable_key
    end

    def create_payment_intent
      response = @payment.payment_method.create_intent(@order.total.to_money.cents, @payment.source)
      if response.success?
        @payment_intent = response
      else
        @payment.send(:gateway_error, response.message)
      end
    end
  end
end

if ::Spree::CheckoutController.included_modules.exclude?(Spree::CheckoutControllerDecorator)
  ::Spree::CheckoutController.prepend Spree::CheckoutControllerDecorator
end
