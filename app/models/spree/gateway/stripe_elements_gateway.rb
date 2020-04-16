module Spree
  class Gateway::StripeElementsGateway < Gateway::StripeGateway
    preference :intents, :boolean

    delegate :create_intent, :update_intent, :confirm_intent, to: :provider

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
        login: preferred_secret_key,
      }.merge! address_for(payment)

      source = update_source!(payment.source)
      if source.gateway_payment_profile_id.present?
        creditcard = source.gateway_payment_profile_id
      else
        creditcard = source
      end
      response = provider.store(creditcard, options)
      if response.success?
        cc_type=payment.source.cc_type
        response_cc_type = response.params['sources']['data'].first['brand']
        cc_type = CARD_TYPE_MAPPING[response_cc_type] if CARD_TYPE_MAPPING.include?(response_cc_type)

        if get_preference(:intents)
          payment.source.update!(
            cc_type: payment.source.cc_type,
            gateway_customer_profile_id: response.params['id'],
            gateway_payment_profile_id: response.params['sources']['data'].first['id']
          )
        else
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
  end
end
