module Spree
  class Gateway::DataCash < Gateway
    preference :login, :string
    preference :password, :string

    attr_accessible :preferred_login, :preferred_password

    def provider_class
      ActiveMerchant::Billing::DataCashGateway
    end
  end
end
