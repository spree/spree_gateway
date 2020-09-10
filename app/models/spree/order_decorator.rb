module Spree
  module OrderDecorator
    def self.prepended(base)
      return if base.checkout_steps.has_key?(:payment_confirm)

      base.insert_checkout_step(
        :payment_confirm,
        before: :complete, #complete, confirm
        if: ->(order) do
          order.payments.valid.map { |p| p.payment_method&.has_preference?(:intents) && p.payment_method&.get_preference(:intents) }.any?
        end
      )
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)
