module SpreeUsaEpay
  class Client
    attr_accessor :source_key, :pin, :test_mode

    def initialize(options)
      @source_key = options[:source_key]
      @pin = options[:pin]
      @test_mode = options[:test_mode]
      @client = Savon::Client.new(soap_url)
    end

    def request(name, body)
      begin
        @client.request name do
          soap.body = body
        end
      rescue Exception => e
        raise Spree::Core::GatewayError.new(e.message)
      end
    end

    def authorize(amount, creditcard, gateway_options)
      if creditcard.gateway_customer_profile_id?
        run_customer_transaction('AuthOnly', amount, creditcard, gateway_options)
      else
        token = security_token(gateway_options)
        request = transaction_request_object(amount, creditcard, gateway_options)
        response = request(:run_auth_only, { "Token" => token, "Params" => request })
        billing_response response[:run_auth_only_response][:run_auth_only_return]
      end
    end


    def purchase(amount, creditcard, gateway_options)
      if creditcard.gateway_customer_profile_id?
        run_customer_transaction('Sale', amount, creditcard, gateway_options)
      else
        token = security_token(gateway_options)
        request = transaction_request_object(amount, creditcard, gateway_options)
        response = request(:run_transaction, { "Token" => token, "Params" => request })
        billing_response response[:run_transaction_response][:run_transaction_return]
      end
    end

    def add_customer(amount, creditcard, gateway_options)
      token = security_token(gateway_options)
      customer = customer_data(amount, creditcard, gateway_options)

      response = request(:add_customer, { "Token" => token, "CustomerData" => customer })
      response[:add_customer_response][:add_customer_return]
    end

    #http://wiki.usaepay.com/developer/soap-1.4/methods/runcustomertransaction
    def capture(payment, creditcard, gateway_options)
      response = request(:capture_transaction, { 'Token' => security_token(gateway_options),
                                                 'RefNum' => payment.response_code,
                                                 'Amount' => payment.amount })
      billing_response response[:capture_transaction_response][:capture_transaction_return]
    end

    def credit(amount, creditcard, response_code, gateway_options)
      if creditcard.gateway_customer_profile_id?
        run_customer_transaction('Credit', amount, creditcard, gateway_options)
      else
        token = security_token(gateway_options)
        request = transaction_request_object(amount, creditcard, gateway_options)

        response = request(:run_credit, { "Token" => token, "Params" => request })
        billing_response response[:run_credit_response][:run_credit_return]
      end
    end

    def void(response_code, *args)
      gateway_options = args.last
      response = request(:void_transaction, { "Token" => security_token(gateway_options), "RefNum" => response_code })
      success = response[:void_transaction_response][:void_transaction_return] #just returns true
      ActiveMerchant::Billing::Response.new(success, "", {}, {})
    end

    private

    def soap_url
      if @test_mode
        "https://sandbox.usaepay.com/soap/gate/DFBAABC3/usaepay.wsdl"
      else
        "https://www.usaepay.com/soap/gate/DFBAABC3/usaepay.wsdl"
      end
    end

    #http://wiki.usaepay.com/developer/soap-1.4/methods/runcustomertransaction
    # Commands are Sale, AuthOnly, Credit, Check and CheckCredit
    def run_customer_transaction(command, amount, creditcard, gateway_options)
      return unless creditcard.gateway_customer_profile_id?

      token = security_token(gateway_options)
      request = customer_transaction_request(amount, creditcard, gateway_options)
      request['Command'] = command

      response = request(:run_customer_transaction,{"Token" => token,
                                                    "CustNum" => creditcard.gateway_customer_profile_id,
                                                    "PaymentMethodID" => creditcard.gateway_payment_profile_id,
                                                    "Parameters" =>  request })
      billing_response response[:run_customer_transaction_response][:run_customer_transaction_return]
    end

    def billing_response(response)
      options = {
        :authorization => response[:ref_num],
        :avs_result => { :code => response[:avs_result_code].to_s },
        :cvv_result => response[:card_code_result],
        :test => @test_mode
      }

      case response[:result_code].to_s
        when "A"
          success = true
          message = response[:result]
        when "D"
          success = false
          message = response[:result]
        when "E"
          success = false
          message = response[:error]
        else
          success = false
          message = "Unexpected result_code from USA Epay"
      end

      ActiveMerchant::Billing::Response.new(success, message, {}, options)
    end

    #http://wiki.usaepay.com/developer/soap-1.4/objects/uesecuritytoken
    def security_token(gateway_options)
      t = Time.now
      hash = Hash.new
      hash["Seed"] = "#{t.year}#{t.month}#{t.day}#{t.hour}#{rand(1000)}"
      hash["Type"] = 'sha1'

      prehash = "#{@source_key}#{hash["Seed"]}#{@pin.to_s.strip}"
      hash["HashValue"] = Digest::SHA1.hexdigest(prehash).to_s

      token = Hash.new
      token["ClientIP"] = gateway_options[:ip]
      token["PinHash"] = hash
      token["SourceKey"] = @source_key
      token
    end

    #http://wiki.usaepay.com/developer/soap-1.4/objects/transactionrequestobject
    def transaction_request_object(amount, creditcard, gateway_options)
     {  'AccountHolder' => creditcard.name,
        'ClientIP' => gateway_options[:ip],
        'Details' => transaction_details(amount, creditcard, gateway_options),
        'BillingAddress' => address_hash(creditcard, gateway_options, :billing_address),
        'ShippingAddress' => address_hash(creditcard, gateway_options, :shipping_address),
        'CreditCardData' => {
          'CardNumber' => creditcard.number,
          'CardExpiration' => expiration_date(creditcard),
          'AvsStreet' => gateway_options[:billing_address][:address1],
          'AvsZip' => gateway_options[:billing_address][:zip],
          'CardCode' => creditcard.verification_value } }
    end

    #http://wiki.usaepay.com/developer/soap-1.4/objects/transactiondetail
    def transaction_details(amount, creditcard, gateway_options)
      { 'Description' => gateway_options[:customer],
        'Amount' => double_money(amount),
        'Tax' => double_money(gateway_options[:tax]),
        'Subtotal' => double_money(gateway_options[:subtotal]),
        'Shipping' => double_money(gateway_options[:shipping]),
        'Discount' => double_money(gateway_options[:discount]),
        'OrderID' => gateway_options[:order_id] }
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

    #http://wiki.usaepay.com/developer/soap-1.4/objects/customertransactionrequest
    def customer_transaction_request(amount, creditcard, gateway_options)
      { 'Command' => 'Sale',
        'ClientIP' => gateway_options[:ip],
        'isRecurring' => false,
        'Details' => transaction_details(amount, creditcard, gateway_options) }
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

