
#/app/models/spree/gateway/opp.rb
class Spree::Gateway::OPP < Spree::Gateway  
  preference :userId, :string
  preference :password, :string
  preference :entityId, :string

  def provider_class
    ActiveMerchant::Billing::OppGateway
  end
end
