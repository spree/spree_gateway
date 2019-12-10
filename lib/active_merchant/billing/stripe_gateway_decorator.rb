module ActiveMerchant
  module Billing
    module StripeGatewayDecorator
      private

      def headers(options = {})
        headers = super
        headers['User-Agent'] = headers['X-Stripe-Client-User-Agent']
        headers
      end

      def add_customer_data(post, options)
        super
        post[:payment_user_agent] = "SpreeGateway/#{SpreeGateway.version}"
      end
    end
  end
end

ActiveMerchant::Billing::StripeGateway.prepend(ActiveMerchant::Billing::StripeGatewayDecorator)
