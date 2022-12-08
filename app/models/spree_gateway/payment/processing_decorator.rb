module SpreeGateway
  module Payment
    module ProcessingDecorator

      def create_intent!
        process_create_intent
      end

      private

      def process_create_intent
        started_creating_intent!
        gateway_action(nil, :create_intent, :intent_created)
      end

    end
  end
end

::Spree::Payment.prepend(::SpreeGateway::Payment::ProcessingDecorator)
