module Spree
  class ApplePayDomainVerificationController < ::ActionController::Base
    def show
      gateway = Spree::Gateway::StripeApplePayGateway.active.last

      raise ActiveRecord::RecordNotFound unless gateway

      render plain: gateway.preferred_domain_verification_certificate
    end
  end
end
