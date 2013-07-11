module Spree
  class Gateway::PinGateway < Gateway
    preference :api_key, :string
    preference :currency, :string, :default => 'AUD'

    attr_accessible :preferred_api_key, :preferred_currency


    def provider_class
      ActiveMerchant::Billing::PinGateway
    end
  end
end
