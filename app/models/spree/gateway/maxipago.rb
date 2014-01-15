module Spree
  class Gateway::Maxipago < Gateway
    preference :login, :string # ID
    preference :password, :string # KEY

    def provider_class
      ActiveMerchant::Billing::MaxipagoGateway
    end

    def auto_capture?
      true
    end
  end
end
