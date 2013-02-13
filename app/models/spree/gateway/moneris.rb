module Spree
  class Gateway::Moneris < Gateway
    preference :login, :string
    preference :password, :password
    
    attr_accessible :preferred_login, :preferred_password

    def provider_class
      ActiveMerchant::Billing::MonerisGateway
    end
    
  end
end
