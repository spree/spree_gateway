module Spree
  class Gateway::CardSave < Gateway
    preference :login, :string
    preference :password, :string
    
    attr_accessible :preferred_login, :preferred_password

    def provider_class
      ActiveMerchant::Billing::CardSaveGateway
    end
  end
end