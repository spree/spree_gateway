module Spree
  class Gateway::UsaEpay < Gateway
    preference :source_key, :string
    preference :pin, :string

    attr_accessible :preferred_source_key, :preferred_pin, :gateway_payment_profile_id
    
    def provider_class
      SpreeUsaEpay::Client
    end

    def payment_profiles_supported?
      true
    end

    def create_profile(payment)
      amount = (payment.amount * 100).round
      creditcard = payment.source
      gateway_options = if creditcard.respond_to?(:gateway_options)
        creditcard.gateway_options(payment)
      else
        payment.send(:gateway_options)
      end

      if creditcard.gateway_customer_profile_id.nil?
        profile_id = provider.add_customer(amount, creditcard, gateway_options)
        creditcard.update_attributes(:gateway_customer_profile_id => profile_id,
                                     :gateway_payment_profile_id => 0)
      end
    end

  end
end
