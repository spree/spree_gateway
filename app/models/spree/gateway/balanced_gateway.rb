module Spree
  class Gateway::BalancedGateway < Gateway
    preference :login, :string
    preference :password, :string
    preference :on_behalf_of_uri, :string

    attr_accessible :preferred_login, :preferred_password, :preferred_on_behalf_of_uri
    
    def provider_class
      ActiveMerchant::Billing::BalancedGateway
    end

    def options_with_test_preference
      options_without_test_preference.merge(:test => self.preferred_test_mode)
    end

    alias_method_chain :options, :test_preference
  end
end
