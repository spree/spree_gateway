module Spree
  class ApplePayDomainVerificationController < Spree::BaseController
    def show
      gateway = Spree::Gateway::StripeApplePayGateway.active.last

      render plain: gateway.preferred_domain_verification_certificate
    end
  end
end
