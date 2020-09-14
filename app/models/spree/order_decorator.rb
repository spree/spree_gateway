module Spree
  module OrderDecorator
    def self.prepended(base)
      return if base.checkout_steps.key?(:payment_confirm)

      base.insert_checkout_step(
        :payment_confirm,
        after: :payment,
        if: lambda do |order|
          order.payments.valid.map { |p| p.payment_method&.has_preference?(:intents) && p.payment_method&.get_preference(:intents) }.any?
        end
      )
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)
