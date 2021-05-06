class AddCreditCardWalletType < ActiveRecord::Migration[6.0]
  def change
      add_column :spree_credit_cards, :tokenization_method, :string, null: true
  end
end
