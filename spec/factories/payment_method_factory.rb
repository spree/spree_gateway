Factory.define(:skrill_quick_checkout, :class => BillingIntegration::Skrill::QuickCheckout) do |record|
  record.name 'Skrill - Quick Checkout'
  record.environment 'test'
end
