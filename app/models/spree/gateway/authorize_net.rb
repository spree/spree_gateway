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

    def cancel(response_code)
      provider
      # From: http://community.developer.authorize.net/t5/The-Authorize-Net-Developer-Blog/Refunds-in-Retail-A-user-friendly-approach-using-AIM/ba-p/9848
      # DD: if unsettled, void needed
      response = provider.void(response_code)
      # DD: if settled, credit/refund needed (CAN'T DO WITHOUT CREDIT CARD ON AUTH.NET)
      #response = provider.refund(response_code) unless response.success?
      
      response
    end

    alias_method_chain :options, :test_preference
  end
end
