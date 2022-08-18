class AddIntentIdToPayments < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_payments, :intent_id, :string
  end
end
