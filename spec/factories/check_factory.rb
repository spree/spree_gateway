FactoryBot.define do
  factory :check, class: Spree::Check do
    account_holder_name { 'John Doe' }
    account_holder_type { 'Individual' }
    account_type { 'checking' }
    routing_number { '110000000' }
    account_number { '000123456789' }
    association(:payment_method, factory: :credit_card_payment_method)
  end
end
