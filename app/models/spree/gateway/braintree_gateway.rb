module Spree
  class Gateway::BraintreeGateway < Gateway
    preference :environment, :string
    preference :merchant_id, :string
    preference :merchant_account_id, :string
    preference :public_key, :string
    preference :private_key, :string
    preference :client_side_encryption_key, :text

    CARD_TYPE_MAPPING = {
      'American Express' => 'american_express',
      'Diners Club' => 'diners_club',
      'Discover' => 'discover',
      'JCB' => 'jcb',
      'Laser' => 'laser',
      'Maestro' => 'maestro',
      'MasterCard' => 'master',
      'Solo' => 'solo',
      'Switch' => 'switch',
      'Visa' => 'visa'
    }

    def provider
      provider_instance = super
      Braintree::Configuration.custom_user_agent = "Spree #{Spree.version}"
      Braintree::Configuration.environment = preferred_environment.to_sym
      Braintree::Configuration.merchant_id = preferred_merchant_id
      Braintree::Configuration.public_key = preferred_public_key
      Braintree::Configuration.private_key = preferred_private_key

      provider_instance
    end

    def provider_class
      ActiveMerchant::Billing::BraintreeBlueGateway
    end

    def authorize(money, creditcard, options = {})
      adjust_options_for_braintree(creditcard, options)
      payment_method = creditcard.gateway_customer_profile_id || creditcard
      provider.authorize(money, payment_method, options)
    end

    def capture(authorization, ignored_creditcard, ignored_options)
      amount = (authorization.amount * 100).to_i
      provider.capture(amount, authorization.response_code)
    end

    def create_profile(payment)
      if payment.source.gateway_customer_profile_id.nil?
        response = provider.store(payment.source)
        if response.success?
          payment.source.update_attributes!(:gateway_customer_profile_id => response.params['customer_vault_id'])
          cc = response.params['braintree_customer'].fetch('credit_cards',[]).first
          update_card_number(payment.source, cc) if cc
        else
          payment.send(:gateway_error, response.message)
        end
      end
    end

    def update_card_number(source, cc)
      last_4 = cc['last_4']
      source.last_digits = last_4 if last_4
      source.gateway_payment_profile_id = cc['token']
      source.cc_type = CARD_TYPE_MAPPING[cc['card_type']] if cc['card_type']
      source.save!
    end

    def credit(*args)
      if args.size == 4
        # enables ability to refund instead of credit
        args.slice!(1,1)
        credit_without_payment_profiles(*args)
      elsif args.size == 3
        credit_without_payment_profiles(*args)
      else
        raise ArgumentError, "Expected 3 or 4 arguments, received #{args.size}"
      end
    end

    # Braintree now disables credits by default, see https://www.braintreepayments.com/docs/ruby/transactions/credit
    def credit_with_payment_profiles(amount, payment, response_code, option)
      provider.credit(amount, payment)
    end

    def credit_without_payment_profiles(amount, response_code, options)
      provider # braintree provider needs to be called here to properly configure braintree gem.
      transaction = ::Braintree::Transaction.find(response_code)
      if BigDecimal.new(amount.to_s) == (transaction.amount * 100)
        provider.refund(response_code)
      elsif BigDecimal.new(amount.to_s) < (transaction.amount * 100) # support partial refunds
        provider.refund(amount, response_code)
      else
        raise NotImplementedError
      end
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, options = {})
      authorize(money, creditcard, options.merge(:submit_for_settlement => true))
    end

    def void(response_code, *ignored_options)
      provider.void(response_code)
    end

    def options
      h = super
      # We need to add merchant_account_id only if present when creating BraintreeBlueGateway
      # Remove it since it is always part of the preferences hash.
      if h[:merchant_account_id].blank?
        h.delete(:merchant_account_id) 
      end 
      h
    end

    def preferences
      preferences = super.slice(:merchant_id,
                                :merchant_account_id,
                                :public_key,
                                :private_key,
                                :client_side_encryption_key,
                                :environment)

      # Must be either :production or :sandbox, not their string equivalents.
      # Thanks to the Braintree gem.
      preferences[:environment] = preferences[:environment].try(:to_sym) || :sandbox
      preferences
    end

    protected

      def adjust_billing_address(creditcard, options)
        if creditcard.gateway_customer_profile_id
          options.delete(:billing_address)
        end
      end

      def adjust_options_for_braintree(creditcard, options)
        adjust_billing_address(creditcard, options)
      end
  end
end
