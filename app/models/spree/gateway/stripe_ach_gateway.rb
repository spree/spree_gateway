module Spree
  class Gateway::StripeAchGateway < Gateway::StripeGateway

    def method_type
      'stripe_ach'
    end

    def payment_source_class
      Check
    end

    def verify(source, gateway_options)
      provider.verify(source, gateway_options)
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

    def supports?(_source)
      true
    end

    def available_for_order?(order)
      # Stripe ACH payments are supported only for US customers
      # Therefore we need to check order's addresses
      return unless order.ship_address_id && order.bill_address_id
      return unless order.ship_address && order.bill_address_id

      usa_id = ::Spree::Country.find_by(iso: 'US')&.id
      return false unless usa_id

      order.ship_address.country_id == usa_id && order.bill_address.country_id == usa_id
    end
  end
end
