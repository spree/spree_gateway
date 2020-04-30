class AddIntentKeyToPayment < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_payments, :intent_client_key, :string
  end
end
