module Spree
  module CreditCardDecorator
    def set_last_digits
      self.last_digits ||= number.to_s.length <= 4 ? number : number.to_s.slice(-4..-1)
    end

  end
end

::Spree::CreditCard.prepend(::Spree::CreditCardDecorator)
