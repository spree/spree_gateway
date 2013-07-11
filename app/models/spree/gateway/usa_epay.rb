module Spree
  class Gateway::UsaEpay < Gateway
    preference :login, :string

    attr_accessible :preferred_login, :gateway_payment_profile_id
    
    def provider_class
      ActiveMerchant::Billing::UsaEpayGateway
    end
  end
end
