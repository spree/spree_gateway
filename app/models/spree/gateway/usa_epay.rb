module Spree
  class Gateway::UsaEpay < Gateway
    preference :login, :string
    preference :password, :string
    preference :software_id, :string

    attr_accessible :preferred_login, :preferred_password, :preferred_software_id

    def provider_class
      ActiveMerchant::Billing::UsaEpayAdvancedGateway
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      # binding.pry
      provider.purchase(money, active_merchant_creditcard(creditcard), gateway_options)
    end

    def authorize(money, creditcard, gateway_options)
      # binding.pry
      if creditcard.gateway_customer_profile_id?
        cust_id = creditcard.gateway_customer_profile_id
        gateway_options.merge(:customer_number => cust_id)
        provider.authorize(money, active_merchant_creditcard(creditcard), gateway_options)
      end
    end

    def capture(payment, creditcard, gateway_options)
      # binding.pry
      provider.capture(payment, creditcard, gateway_options)
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
        customer = customer_data(amount, creditcard, gateway_options)
        binding.pry
        profile_id = provider.add_customer(customer).message
        creditcard.update_attributes(:gateway_customer_profile_id => profile_id,
                                     :gateway_payment_profile_id => 0)
      end
    end

    private

    def active_merchant_creditcard(cc)
      ActiveMerchant::Billing::CreditCard.new(
        :first_name => cc.first_name,
        :last_name  => cc.last_name,
        :month      => cc.month,
        :year       => cc.year,
        :brand      => cc.cc_type,
        :number     => cc.number
      )
    end

    #http://wiki.usaepay.com/developer/soap-1.4/objects/customerobject
    def customer_data(amount, creditcard, gateway_options)
      { 'Amount' => double_money(amount),
        'Enabled' => false,
        'BillingAddress' => address_hash(creditcard, gateway_options, :billing_address),
        'PaymentMethods' => ['PaymentMethod' => { 'MethodType' => 'CreditCard',
                                                  'MethodName' => creditcard.cc_type,
                                                  "SecondarySort" => 1,
                                                  'CardNumber' => creditcard.number,
                                                  'CardExpiration' => expiration_date(creditcard),
                                                  'CardCode' => creditcard.verification_value,
                                                  'AvsStreet' => gateway_options[:billing_address][:address1],
                                                  'AvsZip' => gateway_options[:billing_address][:zip]
                                                 }] }
    end

    def double_money(value)
      (value.to_f/100.00).round(2)
    end

    def address_hash(creditcard, gateway_options, address_key)
      { 'FirstName' => creditcard.first_name,
        'LastName' => creditcard.last_name,
        'Email' => gateway_options[:email],
        'Phone' => gateway_options[address_key][:phone],
        'Street' => gateway_options[address_key][:address1],
        'Street2' => gateway_options[address_key][:address2],
        'City' => gateway_options[address_key][:city],
        'State' => gateway_options[address_key][:state],
        'Country' => gateway_options[address_key][:country],
        'Zip' => gateway_options[address_key][:zip] }
    end

    def expiration_date(creditcard)
      ("%.2i" %  creditcard.month) + creditcard.year[2,2]
    end
  end
end
