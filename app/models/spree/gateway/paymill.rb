module Spree
  class Gateway::Paymill < Gateway

    preference :public_key, :string
    preference :private_key, :string
    preference :currency, :string, :default => 'GBP'

    def provider_class
      ActiveMerchant::Billing::PaymillGateway
    end
    
    def options
      super().merge(:test => self.preferred_test_mode)
    end
    
  end
end
