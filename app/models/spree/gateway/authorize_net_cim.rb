module Spree
  class Gateway::AuthorizeNetCim < Gateway
    preference :login, :string
    preference :password, :string
    preference :server, :string, default: "test"
    preference :test_mode, :boolean, default: false
    preference :validate_on_profile_create, :boolean, default: false

    ActiveMerchant::Billing::Response.class_eval do
      attr_writer :authorization
    end

    def provider_class
      self.class
    end

    def options
      if !['live','test'].include?(self.preferred_server)
        raise "You must set the 'server' preference in your payment method (Gateway::AuthorizeNetCim) to either 'live' or 'test'"
      end

      # add :test key in the options hash, as that is what the
      # ActiveMerchant::Billing::AuthorizeNetGateway expects
      if self.preferred_server != "live"
        self.preferences[:test] = true
      else
        self.preferences.delete(:test)
      end

      super
    end

    def authorize(amount, creditcard, gateway_options)
      create_transaction(amount, creditcard, :auth_only, transaction_options(gateway_options))
    end

    def purchase(amount, creditcard, gateway_options)
      create_transaction(amount, creditcard, :auth_capture, transaction_options(gateway_options))
    end

    # capture is only one where source is not passed in for payment profile
    def capture(amount, response_code, gateway_options)
      # no credit card needed
      create_transaction(amount, nil, :prior_auth_capture, trans_id: response_code)
    end

    def credit(amount, creditcard, response_code, gateway_options = {})
      create_transaction(amount, creditcard, :refund, transaction_options(gateway_options).merge(trans_id: response_code))
    end

    def void(response_code, creditcard, gateway_options = {})
      create_transaction(nil, creditcard, :void, transaction_options(gateway_options).merge(trans_id: response_code))
    end

    def cancel(response_code)
      # From: http://community.developer.authorize.net/t5/The-Authorize-Net-Developer-Blog/Refunds-in-Retail-A-user-friendly-approach-using-AIM/ba-p/9848
      # DD: if unsettled, void needed
      response = void(response_code, nil)
      # DD: if settled, credit/refund needed
      response = credit(nil, nil, response_code) unless response.success?

      response
    end

    def payment_profiles_supported?
      true
    end

    # Create a new CIM customer profile ready to accept a payment. Called by Spree::Payment on after_save.
    def create_profile(payment)
      if payment.source.gateway_customer_profile_id.nil?
        profile_hash = create_customer_profile(payment)
        payment.source.update(gateway_customer_profile_id: profile_hash[:customer_profile_id], gateway_payment_profile_id: profile_hash[:customer_payment_profile_id])
      end
    end

    # Get the CIM payment profile; Needed for updates.
    def get_profile(payment)
      if payment.source.has_payment_profile?
        profile = cim_gateway.get_customer_profile({
          customer_profile_id: payment.source.gateway_customer_profile_id
        })
        if profile
          profile.params['profile'].deep_symbolize_keys!
        end
      end
    end

    # Get the CIM payment profile; Needed for updates.
    def get_payment_profile(payment)
      if payment.source.has_payment_profile?
        profile = cim_gateway.get_customer_payment_profile({
          customer_profile_id: payment.source.gateway_customer_profile_id,
          customer_payment_profile_id: payment.source.gateway_payment_profile_id
        })
        if profile
          profile.params['payment_profile'].deep_symbolize_keys!
        end
      end
    end

    # Update billing address on the CIM payment profile
    def update_payment_profile(payment)
      if payment.source.has_payment_profile?
        if hash = get_payment_profile(payment)
          hash[:bill_to] = generate_address_hash(payment.order.bill_address)
          if hash[:payment][:credit_card]
            # activemerchant expects a credit card object with 'number', 'year', 'month', and 'verification_value?' defined
            payment.source.define_singleton_method(:number) { "XXXXXXXXX#{payment.source.last_digits}" }
            hash[:payment][:credit_card] = payment.source
          end
          cim_gateway.update_customer_payment_profile({
            customer_profile_id: payment.source.gateway_customer_profile_id,
            payment_profile: hash
          })
        end
      end
    end

    private

      def transaction_options(gateway_options = {})
        { order: { invoice_number: gateway_options[:order_id] } }
      end

      # Create a transaction on a creditcard
      # Set up a CIM profile for the card if one doesn't exist
      # Valid transaction_types are :auth_only, :capture_only and :auth_capture
      def create_transaction(amount, creditcard, transaction_type, options = {})
        creditcard.save if creditcard

        transaction_options = {
          type: transaction_type
        }.update(options)

        if amount
          amount = "%.2f" % (amount / 100.0) # This gateway requires formated decimal, not cents
          transaction_options.update({
            amount: amount
          })
        end

        if creditcard
          transaction_options.update({
            customer_profile_id: creditcard.gateway_customer_profile_id,
            customer_payment_profile_id: creditcard.gateway_payment_profile_id
          })
        end

        logger.debug("\nAuthorize Net CIM Request")
        logger.debug("  transaction_options: #{transaction_options.inspect}")
        t = cim_gateway.create_customer_profile_transaction(transaction: transaction_options)
        logger.debug("\nAuthorize Net CIM Response")
        logger.debug("  response: #{t.inspect}\n")
        t
      end

      # Create a new CIM customer profile ready to accept a payment
      def create_customer_profile(payment)
        options = options_for_create_customer_profile(payment)
        response = cim_gateway.create_customer_profile(options)
        if response.success?
          { customer_profile_id: response.params['customer_profile_id'],
            customer_payment_profile_id: response.params['customer_payment_profile_id_list'].values.first }
        else
          payment.send(:gateway_error, response)
        end
      end

      def options_for_create_customer_profile(payment)
        if payment.is_a? CreditCard
          info = { bill_to: generate_address_hash(payment.address),
                   payment: { credit_card: payment } }
        else
          info = { bill_to: generate_address_hash(payment.order.bill_address),
                   payment: { credit_card: payment.source } }
        end
        validation_mode = preferred_validate_on_profile_create ? preferred_server.to_sym : :none

        { profile: { merchant_customer_id: "#{Time.now.to_f}",
                     ship_to_list: generate_address_hash(payment.order.ship_address),
                     email: payment.order.email,
                     payment_profiles: info },
          validation_mode: validation_mode }
      end

      # As in PaymentGateway but with separate name fields
      def generate_address_hash(address)
        return {} if address.nil?
        {
          first_name: address.firstname,
          last_name: address.lastname,
          address1: address.address1,
          address2: address.address2,
          city: address.city,
          state: address.state_text,
          zip: address.zipcode,
          country: address.country.iso,
          phone_number: address.phone
        }
      end

      def cim_gateway
        @_cim_gateway ||= begin
          ActiveMerchant::Billing::Base.gateway_mode = preferred_server.to_sym
          gateway_options = options
          gateway_options[:test_requests] = false # DD: never ever do test requests because just returns transaction_id = 0
          ActiveMerchant::Billing::AuthorizeNetCimGateway.new(gateway_options)
        end
      end

  end
end
