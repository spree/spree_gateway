module SpreeGateway
  module CreditCardDecorator
    def set_last_digits
      self.last_digits ||= number.to_s.length <= 4 ? number : number.to_s.slice(-4..-1)
    end

    def has_intents?
      payment_method.has_preference?(:intents) && payment_method.get_preference(:intents)
    end

    private

    # Card numbers are not required, as source is added via payment_intent.succeeded webhook.
    def require_card_numbers?
      !encrypted_data.present? && !has_payment_profile? && !has_intents?
    end
  end
end

::Spree::CreditCard.prepend(::SpreeGateway::CreditCardDecorator)
