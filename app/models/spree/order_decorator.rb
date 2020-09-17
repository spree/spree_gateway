module Spree
  module OrderDecorator
    def self.prepended(base)
      return if base.checkout_steps.key?(:payment_confirm)

      base.insert_checkout_step(
        :payment_confirm,
        before: :complete,
        if: lambda do |order|
          order.payments.valid.map { |p| p.payment_method&.has_preference?(:intents) && p.payment_method&.get_preference(:intents) }.any?
        end
      )
    end

    def process_payments!
      # Payments are processed in confirm_payment step where after successful
      # 3D Secure authentication `intent_client_key` is saved for payment.
      # In case authentication is unsuccessful, `intent_client_key` is removed.
      return unless payments.last.intent_client_key.nil?

      super
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)
