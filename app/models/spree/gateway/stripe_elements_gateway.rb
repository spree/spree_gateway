module Spree
  class Gateway::StripeElementsGateway < Gateway::StripeGateway
    preference :intents, :boolean, default: true

    def method_type
      'stripe_elements'
    end

    def provider_class
      if get_preference(:intents)
        ActiveMerchant::Billing::StripePaymentIntentsGateway
      else
        ActiveMerchant::Billing::StripeGateway
      end
    end

    def create_profile(payment)
      return unless payment.source.gateway_customer_profile_id.nil?

      options = {
        email: payment.order.email,
        login: preferred_secret_key
      }.merge! address_for(payment)

      source = update_source!(payment.source)
      creditcard = source.gateway_payment_profile_id.present? ? source.gateway_payment_profile_id : source
      response = provider.store(creditcard, options)
      if response.success?
        if get_preference(:intents)
          payment.source.update!(
            cc_type: payment.source.cc_type,
            gateway_customer_profile_id: response.params['id'],
            gateway_payment_profile_id: response.params['sources']['data'].first['id']
          )
        else
          response_cc_type = response.params['sources']['data'].first['brand']
          cc_type = CARD_TYPE_MAPPING.include?(response_cc_type) ? CARD_TYPE_MAPPING[response_cc_type] : payment.source.cc_type
          payment.source.update!({
            cc_type: cc_type, # side-effect of update_source!
            gateway_customer_profile_id: response.params['id'],
            gateway_payment_profile_id: response.params['default_source'] || response.params['default_card']
          })
        end
      else
        payment.send(:gateway_error, response.message)
      end
    end

    private

    def options_for_purchase_or_auth(money, creditcard, gateway_options)
      money, creditcard, options = super
      options[:execute_threed] = get_preference(:intents)
      return money, creditcard, options
    end

    def public_preference_keys
      %i[publishable_key test_mode intents]
    end
  end
end
