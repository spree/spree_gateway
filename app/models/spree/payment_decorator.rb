module Spree
  module PaymentDecorator
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

Spree::Payment.prepend Spree::PaymentDecorator
