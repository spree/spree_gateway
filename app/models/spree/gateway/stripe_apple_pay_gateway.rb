module Spree
  class Gateway::StripeApplePayGateway < Gateway::StripeGateway
    preference :country_code, :string, default: 'US'
    preference :domain_verification_certificate, :text

    def method_type
      'stripe_apple_pay'
    end
  end
end
