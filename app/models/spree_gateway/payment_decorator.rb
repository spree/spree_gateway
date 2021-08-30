module SpreeGateway
  module PaymentDecorator
    def handle_response(response, success_state, failure_state)
      if response.success? && response.respond_to?(:params)
        self.intent_client_key = response.params['client_secret'] if response.params['client_secret']
      end
      super
    end

    def verify!(**options)
      process_verification(options)
    end

    private

    def process_verification(**options)
      protect_from_connection_error do
        response = payment_method.verify(source, options)

        record_response(response)

        if response.success?
          unless response.authorization.nil?
            self.response_code = response.authorization

            source.update(status: response.params['status'])
          end
        else
          gateway_error(response)
        end
      end
    end
  end
end

::Spree::Payment.prepend(::SpreeGateway::PaymentDecorator)
