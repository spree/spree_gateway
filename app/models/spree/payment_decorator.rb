module Spree
  module PaymentDecorator
    def handle_response(response, success_state, failure_state)
      self.intent_client_key = response.params['client_secret'] if response.params['client_secret']
      super
    end
  end
end

Spree::Payment.prepend(Spree::PaymentDecorator)
