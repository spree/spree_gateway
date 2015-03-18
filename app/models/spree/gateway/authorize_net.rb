module Spree
  class Gateway::AuthorizeNet < Gateway
    preference :login, :string
    preference :password, :string

    def provider_class
      ActiveMerchant::Billing::AuthorizeNetGateway
    end

    def options_with_test_preference
      options_without_test_preference.merge(test: self.preferred_test_mode)
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
