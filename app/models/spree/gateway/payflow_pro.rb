module Spree
  class Gateway::PayflowPro < Gateway
    preference :login, :string
    preference :password, :password
    preference :partner, :string

    def provider_class
      ActiveMerchant::Billing::PayflowGateway
    end

    def options
      super().merge(:test => self.preferred_test_mode)
    end
  end
end
