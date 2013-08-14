module Spree
  class Gateway::Moneris < Gateway
    preference :login, :string
    preference :password, :password

    def provider_class
      ActiveMerchant::Billing::MonerisGateway
    end
    
  end
end
