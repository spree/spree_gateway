module Spree
  class Gateway::Eway < Gateway
    preference :login, :string
    
    attr_accessible :preferred_login

    # Note: EWay supports purchase method only (no authorize method).
    # Ensure Spree::Config[:auto_capture] is set to true

    def provider_class
      ActiveMerchant::Billing::EwayGateway
    end

    def options_with_test_preference
      options_without_test_preference.merge(:test => self.preferred_test_mode)
    end

    alias_method_chain :options, :test_preference
  end
end
