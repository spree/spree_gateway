module Spree
  class Gateway::PayJunction < Gateway
    preference :login, :string
    preference :password, :string
    preference :server, :string, :default => "live"

       # WARNING: Unlike other payment integrations, 'test mode' in Authorize Net's termiminology does not mean use test server
       # instead, use preferred server set to either 'live' or 'test'
       # DO NOT TURN TEST MODE TO ON (EVEN IN QA/STAGING ENVIRONMENTS), it will return 0 as transaction ids under all circumstances

       # here, it overloads the setting on the base class, which confusingly defaults to true
       preference :test_mode, :boolean, :default => false

    def provider_class
      ActiveMerchant::Billing::PayJunctionGateway
    end

    def options_with_test_preference
      if !['live','test'].include?(self.preferred_server)
  ActiveSupport::Deprecation.warn("You must set your preferred server to either 'live' or 'test'")
end
# warning: 'test' parameter indicates live or test server; it DOES NOT indicate Authorize.net test-mode
options_without_test_preference.merge(:test => (self.preferred_server != "live") )
    end

    alias_method_chain :options, :test_preference
  end
end
