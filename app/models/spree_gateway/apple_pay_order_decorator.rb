module SpreeGateway
  module ApplePayOrderDecorator
    def confirmation_required?
      return false if paid_with_apple_pay?

      # Little hacky fix for #4117
      # If this wasn't here, order would transition to address state on confirm failure
      # because there would be no valid payments any more.
      Spree::Config[:always_include_confirm_step] ||
        payments.valid.map(&:payment_method).compact.any?(&:payment_profiles_supported?) ||
        confirm?
    end

    def paid_with_apple_pay?
      payments.valid.any?(&:apple_pay?)
    end
  end
end

::Spree::Order.prepend(::SpreeGateway::ApplePayOrderDecorator)
