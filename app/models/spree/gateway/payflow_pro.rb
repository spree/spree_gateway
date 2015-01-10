module Spree
  class Gateway::PayflowPro < Gateway
    preference :login, :string
    preference :password, :password
    preference :partner, :string

    def provider_class
      ActiveMerchant::Billing::PayflowGateway
    end

    def options_with_test_preference
      options_without_test_preference.merge(:test => self.preferred_test_mode)
    end

    alias_method_chain :options, :test_preference

  end
end
