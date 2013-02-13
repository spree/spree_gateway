module Spree
  class Gateway::StripeGateway < Gateway
    preference :login, :string
    preference :currency, :string, :default => 'USD'        #stripes only supports USD and CAD

    attr_accessible :preferred_login, :preferred_currency

    # Make sure to have Spree::Config[:auto_capture] set to true.

    def provider_class
      ActiveMerchant::Billing::StripeGateway
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      options = {}
      options[:description] = "Spree Order ID: #{gateway_options[:order_id]}"
      options[:currency] = preferred_currency
      if customer = creditcard.gateway_customer_profile_id
        options[:customer] = customer
        creditcard = nil
      elsif token = creditcard.gateway_payment_profile_id
        # The Stripe ActiveMerchant gateway supports passing the token directly as the creditcard parameter
        creditcard = token
      end
      provider.purchase(money, creditcard, options)
    end

    def authorize(money, creditcard, gateway_options)
      raise "Stripe does not currently support separate auth and capture; ensure Spree::Config[:auto_capture] is set to true"
    end

    def capture(authorization, creditcard, gateway_options)
      raise "Stripe does not currently support separate auth and capture; ensure Spree::Config[:auto_capture] is set to true"
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    def void(response_code, creditcard, gateway_options)
      provider.void(response_code, {})
    end

    def create_profile(payment)
      return unless payment.source.gateway_customer_profile_id.nil?

      options = {}
      options[:email] = payment.order.email
      options[:login] = preferred_login
      response = provider.store(payment.source, options)
      if response.success?
        payment.source.update_attributes!(:gateway_customer_profile_id => response.params['id'])
      else
        payment.send(:gateway_error, response.message)
      end
    end
  end
end
