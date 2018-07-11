module Spree
  class Gateway::StripeElementsGateway < Gateway::StripeGateway
    def method_type
      'stripe_elements'
    end
  end
end
