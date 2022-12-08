module SpreeGateway
  module Order
    module PaymentsDecorator

      def unprocessed_payments
        payments.select(&:checkout_or_intent?)
      end

    end
  end
end

::Spree::Order::Payments.prepend(::SpreeGateway::Order::PaymentsDecorator)
