module SpreeGateway
  module OrderDecorator
    def self.prepended(base)
      return if base.checkout_steps.key?(:payment_confirm)

      base.insert_checkout_step(
        :payment_confirm,
        before: :complete,
        if: ->(order) { order.intents? }
      )
    end

    def process_payments!
      # Payments are processed in confirm_payment step where after successful
      # 3D Secure authentication `intent_client_key` is saved for payment.
      # In case authentication is unsuccessful, `intent_client_key` is removed.
      return if intents? && payments.valid.last.intent_client_key.present?

      super
    end

    def intents?
      payments.valid.map { |p| p.payment_method&.has_preference?(:intents) && p.payment_method&.get_preference(:intents) }.any?
    end
  end
end

::Spree::Order.prepend(::SpreeGateway::OrderDecorator)
