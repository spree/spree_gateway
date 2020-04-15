module Spree
  module PaymentDecorator
    def prepended(base)
      base.after_create do
        return unless source.payment_method.has_preference?(:intents)
        if source.payment_method.get_preference(:intents)
          create_intent(order)
        end
      end
    end

    def create_intent(order)
      source.payment_method.create_intent(
        (order.total * 100).to_i,
        source.payment_method.id,
        currency: order.currency
      )
    end
  end
end
::Spree::Payment.prepend(Spree::PaymentDecorator)
