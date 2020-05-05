module Spree
  module OrderDecorator
    def self.prepended(base)
      base.insert_checkout_step(:payment_confirm, after: :confirm, if: ->(order) { order.payments.map { |p| p.payment_method&.has_preference?(:intents) && p.payment_method&.get_preference(:intents) }.any? }) unless base.checkout_steps.has_key?(:payment_confirm)
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)

