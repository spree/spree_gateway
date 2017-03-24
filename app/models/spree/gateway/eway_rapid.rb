module Spree
  class Gateway::EwayRapid < Gateway
    preference :login, :string
    preference :password, :string

    def provider_class
      ActiveMerchant::Billing::EwayRapidGateway
    end
  end
end
