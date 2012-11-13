module Spree
  class Gateway::Banwire < Gateway
    preference :login, :string

    attr_accessible :preferred_login

    def provider_class
      ActiveMerchant::Billing::BanwireGateway
    end

    def purchase(money, creditcard, gateway_options)
      gateway_options[:description] = "Spree Order"
      provider.purchase(money, creditcard, gateway_options)
    end
  end
end
