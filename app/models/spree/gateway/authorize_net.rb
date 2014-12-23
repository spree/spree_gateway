module Spree
  class Gateway::AuthorizeNet < Gateway
    preference :login, :string
    preference :password, :string
    preference :server, :string, :default => "test"

    def provider_class
      ActiveMerchant::Billing::AuthorizeNetGateway
    end

    def options_with_test_preference
      raise "You must set the 'server' preference in your payment method (Gateway::AuthorizeNet) to either 'live' or 'test'" if !['live','test'].include?(self.preferred_server)
      options_without_test_preference.merge(:test => (self.preferred_server != "live") )
    end

    alias_method_chain :options, :test_preference
  end
end
