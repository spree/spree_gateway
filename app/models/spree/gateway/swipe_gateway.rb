module Spree
  class Gateway::SwipeGateway < Gateway
    preference :login, :string
    preference :api_key, :string
    preference :region, :string

    def provider_class
      ActiveMerchant::Billing::SwipeCheckoutGateway
    end

    # (no authorize method).
    def auto_capture?
      true
    end

    def purchase(money, creditcard, gateway_options)
      gateway_options[:description] = "Spree Checkout - Order " + gateway_options[:order_id]
      money = money.to_f / 100
      provider.purchase(money, creditcard, gateway_options)
    end
  end
end