class ChangeTypeOfPaymentMethodIdAndUserIdForSpreeChecks < ActiveRecord::Migration[4.2]
  def change
    change_table(:spree_checks) do |t|
      t.change :payment_method_id, :bigint
      t.change :user_id, :bigint
    end
  end
end
