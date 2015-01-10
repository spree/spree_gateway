module Spree
  class Gateway::CyberSource < Gateway
    preference :login, :string
    preference :password, :password

    def provider_class
      ActiveMerchant::Billing::CyberSourceGateway
    end
  end
end
