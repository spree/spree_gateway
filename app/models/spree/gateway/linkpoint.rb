module Spree
  class Gateway::Linkpoint < Gateway
    preference :login, :string
    preference :pem, :text
    
    attr_accessible :preferred_login, :preferred_pem

    def provider_class
      ActiveMerchant::Billing::LinkpointGateway
    end
  end
end
