class UpdatePaypalPaymentMethodType < SpreeExtension::Migration[4.2]
  def up
    Spree::PaymentMethod.where(:type => "Spree::Gateway::PayPal").update_all(:type => "Spree::Gateway::PayPalGateway")
  end

  def down
    Spree::PaymentMethod.where(:type => "Spree::Gateway::PayPalGateway").update_all(:type => "Spree::Gateway::PayPal")
  end
end
