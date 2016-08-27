module Spree
  class Gateway::Quickpay < Gateway
    preference :api_key, :string

    def provider_class
      ActiveMerchant::Billing::QuickpayV10Gateway
    end
  end
end
