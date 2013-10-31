module Spree
  class Gateway::SecurePayAU < Gateway
    preference :login, :string
    preference :password, :string

    def provider_class
      ActiveMerchant::Billing::SecurePayAU
    end
  end
end
