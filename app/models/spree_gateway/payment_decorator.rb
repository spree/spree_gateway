module SpreeGateway
  module PaymentDecorator
    def self.prepended(base)
      # Added the 'intent' state to allow payment gateway to handle creation of payment intent.
      # Overridden here for now, but assume this would be better sitting in core.
      base.state_machine initial: :checkout do
        event :started_creating_intent do
          transition from: [:checkout], to: :creating_intent
        end

        event :intent_created do
          transition from: [:creating_intent], to: :intent
        end

        # With card payments, happens before purchase or authorization happens
        #
        # Setting it after creating a profile and authorizing a full amount will
        # prevent the payment from being authorized again once Order transitions
        # to complete
        event :started_processing do
          transition from: [:checkout, :intent, :pending, :completed, :processing], to: :processing
        end
        # When processing during checkout fails
        event :failure do
          transition from: [:creating_intent, :pending, :processing], to: :failed
        end
        # With card payments this represents authorizing the payment
        event :pend do
          transition from: [:checkout, :processing], to: :pending
        end
        # With card payments this represents completing a purchase or capture transaction
        event :complete do
          transition from: [:processing, :pending, :checkout], to: :completed
        end
        event :void do
          transition from: [:pending, :processing, :completed, :checkout], to: :void
        end
        # when the card brand isnt supported
        event :invalidate do
          transition from: [:checkout], to: :invalid
        end

        after_transition do |payment, transition|
          payment.state_changes.create!(
            previous_state: transition.from,
            next_state: transition.to,
            name: 'payment'
          )
        end
      end
    end


    def handle_response(response, success_state, failure_state)
      if response.success? && response.respond_to?(:params)
        self.intent_client_key = response.params['client_secret'] if response.params['client_secret']
        self.intent_id = response.params['id'] if response.params['id']
      end
      super
    end

    def verify!(**options)
      process_verification(options)
    end

    def checkout_or_intent?
      checkout? || intent?
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
