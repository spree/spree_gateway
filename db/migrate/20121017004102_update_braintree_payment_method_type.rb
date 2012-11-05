class UpdateBraintreePaymentMethodType < ActiveRecord::Migration
  def up
    Spree::PaymentMethod.where(:type => "Spree::Gateway::Braintree").update_all(:type => "Spree::Gateway::BraintreeGateway")
  end
  
  def down
    Spree::PaymentMethod.where(:type => "Spree::Gateway::BraintreeGateway").update_all(:type => "Spree::Gateway::Braintree")
  end
end
