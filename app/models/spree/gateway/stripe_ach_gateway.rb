module Spree
  class Gateway::StripeAchGateway < Gateway::StripeGateway

    def method_type
      'stripe_ach'
    end

    def create_profile(payment)
      return unless payment.source&.gateway_customer_profile_id.nil?

      options = {
        email: payment.order.user&.email || payment.order.email,
        login: preferred_secret_key,
      }.merge! address_for(payment)

      source = payment.source
      bank_account = if source.gateway_payment_profile_id.present?
                       source.gateway_payment_profile_id
                     else
                       source
                     end

      response = provider.store(bank_account, options)

      if response.success?
        payment.source.update!({
                                 gateway_customer_profile_id: response.params['id'],
                                 gateway_payment_profile_id: response.params['default_source'] || response.params['default_card']
                               })

      else
        payment.send(:gateway_error, response.message)
      end
    end
  end
end
