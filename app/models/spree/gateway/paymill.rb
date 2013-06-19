module Spree
  class Gateway::Paymill < Gateway
    preference :public_key, :string
    preference :private_key, :string

    attr_accessible :preferred_public_key, :preferred_private_key

    def provider_class
      ActiveMerchant::Billing::PaymillGateway
    end
  end
end
