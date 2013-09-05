module Spree
  class Gateway::Fatzebra < Gateway
    preference :username, :string, default: "TEST"
    preference :token, :string, default: "TEST" 

    def provider_class
      ActiveMerchant::Billing::FatZebraGateway
    end

    # Currently no auth/capture, but coming soon...
    def auto_capture?
      true
    end
  end
end