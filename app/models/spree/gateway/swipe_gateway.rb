module Spree
  class Gateway::SwipeGateway < Gateway
    preference :login, :string
    preference :api_key, :string
    preference :region, :string

    def provider_class
      ActiveMerchant::Billing::SwipeCheckoutGateway
    end

    # (no authorize method).
    def auto_capture?
      true
    end
  end
end