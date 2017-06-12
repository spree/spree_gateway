module Spree
  class Gateway::PayJunction < Gateway
    preference :login, :string
    preference :password, :string

    def provider_class
      ActiveMerchant::Billing::PayJunctionGateway
    end

    def options
      super().merge(:test => self.preferred_test_mode)
    end
  end
end
