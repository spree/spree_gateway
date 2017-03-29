module Spree
  class Gateway::AuthorizeNet < Gateway
    preference :login, :string
    preference :password, :string
    preference :server, :string, :default => "live"

       # WARNING: Unlike other payment integrations, 'test mode' in Authorize Net's termiminology does not mean use test server
       # instead, use preferred server set to either 'live' or 'test'
       # DO NOT TURN TEST MODE TO ON (EVEN IN QA/STAGING ENVIRONMENTS), it will return 0 as transaction ids under all circumstances

       # here, it overloads the setting on the base class, which confusingly defaults to true
       preference :test_mode, :boolean, :default => false

    def provider_class
      ActiveMerchant::Billing::AuthorizeNetGateway
    end

    def options_with_test_preference
      if !['live','test'].include?(self.preferred_server)
    ActiveSupport::Deprecation.warn("You must set your preferred server to either 'live' or 'test'")
  end
  # warning: 'test' parameter indicates live or test server; it DOES NOT indicate Authorize.net test-mode
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

    def credit(amount, response_code, refund, gateway_options = {})
      gateway_options[:card_number] = refund[:originator].payment.source.last_digits
      auth_net_gateway.refund(amount, response_code, gateway_options)
    end

    private

    def auth_net_gateway
      @_auth_net_gateway ||= begin
        ActiveMerchant::Billing::Base.gateway_mode = preferred_server.to_sym
        gateway_options = options
        gateway_options[:test_requests] = false # DD: never ever do test requests because just returns transaction_id = 0
        ActiveMerchant::Billing::AuthorizeNetGateway.new(gateway_options)
      end
    end
  end
end
