module Spree
  class Gateway::PinGateway < Gateway
    preference :api_key, :string
    preference :currency, :string, :default => 'AUD'

    def provider_class
      ActiveMerchant::Billing::PinGateway
    end
    
    def purchase(money, creditcard, options = {})
      super(money, creditcard.try(:gateway_customer_profile_id) || creditcard.try(:gateway_payment_profile_id) || creditcard, options)
    end
    
    def create_profile(payment)
      if payment.source.gateway_customer_profile_id.nil?
        response = provider.store(payment.source, options_for_payment(payment))
        
        if response.success?
          payment.source.update!(:gateway_customer_profile_id => response.authorization)

          cc = response.params['response']['card']
          payment.source.update!(:gateway_payment_profile_id => cc['token']) if cc
        else
          payment.send(:gateway_error, response.message)
        end
      end
    end

    # Pin does not appear to support authorizing transactions yet
    def auto_capture?
      true
    end
    
    def payment_profiles_supported?
      true
    end
    
    private
    
    def options_for_payment(p)
      o = Hash.new
      o[:email] = p.order.email

      if p.order.bill_address
        bill_addr = p.order.bill_address

        o[:billing_address] = {
          address1: bill_addr.address1,
          city: bill_addr.city,
          state: bill_addr.state ? bill_addr.state.name : bill_addr.state_name,
          country: bill_addr.country.iso3,
          zip: bill_addr.zipcode
        }
      end

      return o
    end
    
  end
end
