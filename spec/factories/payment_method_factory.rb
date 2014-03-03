FactoryGirl.define do
  factory :skrill_quick_checkout, class: Spree::BillingIntegration::Skrill::QuickCheckout do
    name 'Skrill - Quick Checkout'
    environment 'test'
  end
end
