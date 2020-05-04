module Spree
  module OrderDecorator
    def self.prepended(base)
      base.checkout_flow do
        go_to_state :address
        go_to_state :delivery
        go_to_state :payment, if: ->(order) { order.payment? || order.payment_required? }
        go_to_state :confirm, if: ->(order) { order.confirmation_required? }
        go_to_state :confirm_payment, if: ->(order) { order.payments.map { |p| p.payment_method.has_preference?(:intents) && p.payment_method.get_preference(:intents) }.any? }
        go_to_state :complete
        remove_transition from: :delivery, to: :confirm, unless: ->(order) { order.confirmation_required? }
      end
    end
  end
end

Spree::Order.prepend(Spree::OrderDecorator)
