module ActiveMerchant
  module Billing
    module StripeGatewayDecorator
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
        JSON.dump(
          {
            lang: 'ruby',
            lang_version: "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} (#{RUBY_RELEASE_DATE})",
            bindings_version: ActiveMerchant::VERSION,
            platform: RUBY_PLATFORM,
            publisher: 'SpreeGateway',
            application: {
              name: 'SpreeGateway',
              version: "#{SpreeGateway.version}",
              partner_id: 'pp_partner_FC3KpLMMQgUgcQ',
              url: 'spreecommerce.org'
            }
          }
        )
      end
    end
  end
end

ActiveMerchant::Billing::StripeGateway.prepend(ActiveMerchant::Billing::StripeGatewayDecorator)
