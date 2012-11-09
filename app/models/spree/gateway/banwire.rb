module Spree
  class Gateway::Banwire < Gateway
    preference :login, :string

    attr_accessible :preferred_login

    def provider_class
      ActiveMerchant::Billing::BanwireGateway
    end
  end
end
