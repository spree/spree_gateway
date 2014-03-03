FactoryGirl.define do
  factory :skrill_transaction, class: Spree::SkrillTransaction do
    email ''
    amount 0.0
    currency 'USD'
    transaction_id nil
    customer_id nil
    payment_type nil
  end
end