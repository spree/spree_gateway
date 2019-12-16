module ActiveMerchant
  module Billing
    module StripeGatewayDecorator
      def self.prepended(base)
        base.class_eval do
          alias_method :original_headers, :headers
          alias_method :original_add_customer_data, :add_customer_data

          private

          def headers(options = {})
            headers = super
            headers['X-Stripe-Client-User-Agent'] = x_stripe_client_user_agent_data
            headers['User-Agent'] = headers['X-Stripe-Client-User-Agent']
            headers
          end

          def add_customer_data(post, options)
            super
            post[:payment_user_agent] = "SpreeGateway/#{SpreeGateway.version}/pp_partner_FC3KpLMMQgUgcQ"
          end

          def x_stripe_client_user_agent_data
            "{
              'lang': 'ruby',
              'publisher': 'SpreeGateway',
              'application': {
                'name': 'SpreeGateway'
                'version': SpreeGateway.version,
                'partner_id': 'pp_partner_FC3KpLMMQgUgcQ',
                'url': 'spreecommerce.org',
              }
            }"
          end
        end
      end
    end
  end
end

ActiveMerchant::Billing::StripeGateway.prepend(ActiveMerchant::Billing::StripeGatewayDecorator)
