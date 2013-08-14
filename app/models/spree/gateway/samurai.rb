module Spree
  class Gateway::Samurai < Gateway
    preference :login, :string
    preference :password, :string
    preference :processor_token, :string

    def provider_class
      ActiveMerchant::Billing::SamuraiGateway
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      gateway_options[:billing_reference] = gateway_options[:order_id]
      gateway_options[:customer_reference] = gateway_options[:customer]
      gateway_options[:description] = "Spree Order"
      provider.purchase(money, creditcard.gateway_customer_profile_id, gateway_options)
    end

    def authorize(money, creditcard, gateway_options)
      gateway_options[:billing_reference] = gateway_options[:order_id]
      gateway_options[:customer_reference] = gateway_options[:customer]
      gateway_options[:description] = "Spree Order"
      provider.authorize(money, creditcard.gateway_customer_profile_id, gateway_options)
    end

    def capture(authorization, creditcard, gateway_options)
      gateway_options[:billing_reference] = gateway_options[:order_id]
      gateway_options[:customer_reference] = gateway_options[:customer]
      gateway_options[:description] = "Spree Order"
      provider.capture(nil, authorization.response_code, {})
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.credit(money, response_code, {})
    end

    def void(response_code, gateway_options)
      provider.void(response_code, {})
    end

    def create_profile(payment)
      return unless payment.source.gateway_customer_profile_id.nil?

      options = {}
      options[:email] = payment.order.email
      options[:address] = {}
      options[:address][:address1] = payment.order.bill_address.address1
      options[:address][:address2] = payment.order.bill_address.address2
      options[:address][:city] = payment.order.bill_address.city
      options[:address][:state] = payment.order.bill_address.state.abbr
      options[:address][:zip] = payment.order.bill_address.zipcode
      response = provider.store(payment.source, options)
      if response.success?
        payment.source.update_attributes!(:gateway_customer_profile_id => response.params['payment_method_token'])
      else
        payment.send(:gateway_error, response.message)
      end
    end
  end
end
