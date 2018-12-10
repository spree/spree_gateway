module SpreeGateway
  module ApplePayOrderDecorator
    def confirmation_required?
      return false if paid_with_apple_pay?

      super
    end

    def paid_with_apple_pay?
      payments.valid.any?(&:apple_pay?)
    end
  end
end

Spree::Order.prepend SpreeGateway::ApplePayOrderDecorator
