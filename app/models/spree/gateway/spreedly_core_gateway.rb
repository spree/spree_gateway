module Spree
  class Gateway::SpreedlyCoreGateway < Gateway
    preference :login, :string
    preference :password, :string
    preference :gateway_token, :string
    def provider_class
      ActiveMerchant::Billing::SpreedlyCoreGateway
    end
  end
end
