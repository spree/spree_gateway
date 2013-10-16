module Spree
  class Gateway::PinGateway < Gateway
    preference :api_key, :string
    preference :currency, :string, :default => 'AUD'

    def provider_class
      ActiveMerchant::Billing::PinGateway
    end

    # Pin does not appear to support authorizing transactions yet
    def auto_capture?
      true
    end
  end
end
