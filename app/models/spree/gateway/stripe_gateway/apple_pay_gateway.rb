module Spree
  class Gateway::StripeGateway::ApplePayGateway < Gateway::StripeGateway
    def method_type
      'applepay'
    end
  end
end
