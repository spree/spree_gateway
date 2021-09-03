require 'spec_helper'

describe Spree::Order do
  let(:order_one) { OrderWalkthrough.up_to(:payment) }
  let(:order_two) { OrderWalkthrough.up_to(:payment) }
  let(:stripe_apple_pay_payment_method) do
    Spree::Gateway::StripeApplePayGateway.create!(
      name: 'ApplePay',
      preferred_domain_verification_certificate: FFaker::Lorem.characters(20),
      stores: [::Spree::Store.default]
    )
  end
  let(:stripe_credit_card_payment_method) do
    Spree::Gateway::StripeGateway.create!(
      name: 'CreditCard',
      preferred_secret_key: FFaker::Lorem.characters(20),
      preferred_publishable_key: FFaker::Lorem.characters(20),
      stores: [::Spree::Store.default]
    )
  end

  before do
    Spree::Config[:always_include_confirm_step] = true
    allow_any_instance_of(Spree::PaymentMethod).to receive(:source_required?).and_return(false)

    order_one.payments.create(payment_method_id: stripe_apple_pay_payment_method.id,
                              amount: 29.99,
                              state: 'completed')
    order_two.payments.create(payment_method_id: stripe_credit_card_payment_method.id,
                              amount: 29.99,
                              state: 'completed')
    order_one.update_totals
    order_two.update_totals
  end

  describe '#paid_with_apple_pay?' do
    context 'when an order was paid with Apply Pay' do
      it 'returns true' do
        expect(order_one.paid_with_apple_pay?).to eq true
      end
    end

    context 'when an order was paid with Credit Card' do
      it 'returns false' do
        expect(order_two.paid_with_apple_pay?).to eq false
      end
    end
  end

  describe '#confirmation_required?' do
    context 'when an order was paid with Apply Pay' do
      it 'returns false' do
        expect(order_one.confirmation_required?).to eq false
      end
    end

    context 'when an order was paid with Credit Card' do
      it 'returns true' do
        expect(order_two.confirmation_required?).to eq true
      end
    end
  end

  context 'when an order was paid with Apply Pay' do
    it 'proceeds to Complete order state' do
      order_one.next

      expect(order_one.state).to eq 'complete'
    end
  end

  context 'when an order was paid with Credit Card' do
    it 'proceeds to Confirm order state' do
      order_two.next

      expect(order_two.state).to eq 'confirm'
    end
  end
end
