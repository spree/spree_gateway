module Spree
  class Gateway::UsaEpayTransaction < Gateway
    preference :login, :string

    def provider_class
      ActiveMerchant::Billing::UsaEpayTransactionGateway
    end
  end
end
