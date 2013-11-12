module Spree
  class Gateway::StripeGateway < Gateway
    preference :secret_key, :string
    preference :publishable_key, :string

    def method_type
      'stripe'
    end

    def provider_class
      ActiveMerchant::Billing::StripeGateway
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def authorize(money, creditcard, gateway_options)
      provider.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def capture(payment, creditcard, gateway_options)
      provider.capture((payment.amount * 100).round, payment.response_code, gateway_options)
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    def void(response_code, creditcard, gateway_options)
      provider.void(response_code, {})
    end

    def create_profile(payment)
      return unless payment.source.gateway_customer_profile_id.nil?
      options = {
        email: payment.order.email,
        login: preferred_secret_key,
      }.merge! address_for(payment)

      response = provider.store(payment.source, options)
      if response.success?
        payment.source.update_attributes!({
          :gateway_customer_profile_id => response.params['id'],
          :gateway_payment_profile_id => response.params['default_card']
        })
      else
        payment.send(:gateway_error, response.message)
      end
    end

    private

    # In this gateway, what we call 'secret_key' is the 'login'
    def options
      options = super
      options.merge(:login => preferred_secret_key)
    end


    def options_for_purchase_or_auth(money, creditcard, gateway_options)
      options = {}
      options[:description] = "Spree Order ID: #{gateway_options[:order_id]}"
      options[:currency] = gateway_options[:currency]

      if customer = creditcard.gateway_customer_profile_id
        options[:customer] = customer
      end
      if token_or_card_id = creditcard.gateway_payment_profile_id
        # The Stripe ActiveMerchant gateway supports passing the token directly as the creditcard parameter
        # The Stripe ActiveMerchant gateway supports passing the customer_id and credit_card id
        # https://github.com/Shopify/active_merchant/issues/770
        creditcard = token_or_card_id
      end
      return money, creditcard, options
    end

    def address_for(payment)
      {}.tap do |options|
        if address = payment.order.bill_address
          options.merge!(address: {
            address1: address.address1,
            address2: address.address2,
            city: address.city,
            zip: address.zipcode
          })

          if country = address.country
            options[:address].merge!(country: country.name)
          end

          if state = address.state
            options[:address].merge!(state: state.name)
          end
        end
      end
    end
  end
end
