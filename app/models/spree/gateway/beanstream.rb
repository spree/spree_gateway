module Spree
  class Gateway::Beanstream < Gateway
    preference :login, :string
    preference :user, :string
    preference :password, :string
    preference :secure_profile_api_key, :string

    def provider_class
      ActiveMerchant::Billing::BeanstreamGateway
    end

    def payment_profiles_supported?
      if options[:secure_profile_api_key].empty?
        false
      else
        true 
      end
    end

    def create_profile(payment)
      creditcard = payment.source
      if creditcard.gateway_customer_profile_id.nil?
        options = options_for_create_customer_profile(creditcard, {})
        verify_creditcard_name!(creditcard)
        result = provider.store(creditcard, options)
        if result.success?
          creditcard.update_attributes(:gateway_customer_profile_id => result.params["customerCode"], :gateway_payment_profile_id => result.params["customer_vault_id"])
        else
          creditcard.gateway_error(result) if creditcard.respond_to? :gateway_error
          creditcard.source.gateway_error(result)
        end
      end
    end

    def capture(transaction, creditcard, gateway_options)
      beanstream_gateway.capture((transaction.amount*100).round, transaction.response_code, gateway_options)
    end

    def void(transaction_response, creditcard, gateway_options)
      beanstream_gateway.void(transaction_response, gateway_options)
    end

    def credit(amount, creditcard, response_code, gateway_options = {})
      amount = (amount * -1) if amount < 0
      beanstream_gateway.credit(amount, response_code, gateway_options)
    end

    private

    def beanstream_gateway
      ActiveMerchant::Billing::Base.gateway_mode = preferred_server.to_sym
      gateway_options = options
      ActiveMerchant::Billing::BeanstreamGateway.new(gateway_options)
    end

    def verify_creditcard_name!(creditcard)
      bill_address = creditcard.payments.first.order.bill_address
      creditcard.first_name = bill_address.firstname unless creditcard.first_name?
      creditcard.last_name = bill_address.lastname   unless creditcard.last_name?
    end

    def options_for_create_customer_profile(creditcard, gateway_options)
      order = creditcard.payments.first.order
      address = order.bill_address
      { :email=>order.email,
        :billing_address=>
        { :name=>address.full_name,
          :phone=>address.phone,
          :address1=>address.address1,
          :address2=>address.address2,
          :city=>address.city,
          :state=>address.state_name || address.state.abbr,
          :country=>address.country.iso,
          :zip=>address.zipcode
        }
      }.merge(gateway_options)
    end
  end
end