module Spree
  class ApplePayDomainVerificationController < StoreController
    skip_before_action :set_current_order, only: :show
    include Spree::Core::ControllerHelpers

    def show
      gateway = Spree::Gateway::StripeApplePayGateway.active.first

      render plain: gateway.preferred_domain_verification_certificate
    end
  end
end
