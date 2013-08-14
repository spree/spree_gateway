module Spree
  class BillingIntegration::Skrill::QuickCheckout < BillingIntegration
    preference :merchant_id, :string
    preference :language, :string, :default => 'EN'
    preference :currency, :string, :default => 'EUR'
    preference :payment_options, :string, :default => 'ACC'
    preference :pay_to_email, :string ,   :default => 'your@merchant.email_here' 

    def provider_class
      ActiveMerchant::Billing::Skrill
    end

    def redirect_url(order, opts = {})
      opts.merge! self.preferences

      set_global_options(opts)

      opts[:detail1_text] = order.number
      opts[:detail1_description] = "Order:"

      opts[:pay_from_email] = order.email
      opts[:firstname] = order.bill_address.firstname
      opts[:lastname] = order.bill_address.lastname
      opts[:address] = order.bill_address.address1
      opts[:address2] = order.bill_address.address2
      opts[:phone_number] = order.bill_address.phone.gsub(/\D/,'') if order.bill_address.phone
      opts[:city] = order.bill_address.city
      opts[:postal_code] = order.bill_address.zipcode
      opts[:state] = order.bill_address.state.nil? ? order.bill_address.state_name.to_s : order.bill_address.state.abbr
      opts[:country] = order.bill_address.country.name
      opts[:pay_to_email] = self.preferred_pay_to_email
      opts[:hide_login] = 1
      opts[:merchant_fields] = 'platform,order_id,payment_method_id'
      opts[:platform] = 'Spree'
      opts[:order_id] = order.number

      skrill = self.provider
      skrill.payment_url(opts)
    end

    private
      def set_global_options(opts)
        opts[:recipient_description] = Spree::Config[:site_name]
        opts[:payment_methods] = self.preferred_payment_options
      end

  end
end
