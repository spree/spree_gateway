module Spree
  class Gateway::SagePay < Gateway
    preference :login, :string
    preference :password, :string
    preference :account, :string
    
    attr_accessible :preferred_login, :preferred_password, :preferred_account

    def provider_class
      ActiveMerchant::Billing::SagePayGateway
    end
  end
end
