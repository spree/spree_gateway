module Spree
  class Gateway::Paymill < Gateway

    preference :public_key, :string
    preference :private_key, :string
    preference :currency, :string, :default => 'GBP'

    attr_accessible :preferred_public_key, :preferred_private_key, :preferred_currency


    def provider_class
      ActiveMerchant::Billing::PaymillGateway
    end
  end
end
