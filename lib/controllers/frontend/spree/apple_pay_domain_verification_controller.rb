module Spree
  class ApplePayDomainVerificationController < StoreController
    skip_before_action :set_current_order, only: :show
    include Spree::Core::ControllerHelpers

    def show
      gateway = Gateway.active.find_by!(type: 'Spree::Gateway::StripeApplePayGateway')

      render plain: gateway.preferred_domain_verification_certificate
    end
  end
end