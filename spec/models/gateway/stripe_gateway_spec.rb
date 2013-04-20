require 'spec_helper'

describe Spree::Gateway::StripeGateway do
  let(:login) { 'nothing' }
  let(:email) { 'customer@example.com' }

  let(:payment) {
    stub('Spree::Payment',
      source: stub('Source', gateway_customer_profile_id: nil).as_null_object,
      order: stub('Spree::Order',
        email: email,
        bill_address: bill_address
      )
    )
  }

  before { subject.set_preference :login, login }

  describe '#create_profile' do
    context 'with an order that has a bill address' do
      let(:bill_address) {
        stub('Spree::Address',
          address1: '123 Happy Road',
          address2: 'Apt 303',
          city: 'Suzarac',
          zipcode: '95671',
          state: stub('Spree::State', name: 'Oregon'),
          country: stub('Spree::Country', name: 'United States')
        )
      }

      it 'stores the bill address with the provider' do
        subject.provider.should_receive(:store).with(payment.source, {
          email: email,
          login: login,

          address: {
            address1: '123 Happy Road',
            address2: 'Apt 303',
            city: 'Suzarac',
            zip: '95671',
            state: 'Oregon',
            country: 'United States'
          }
        }).and_return stub.as_null_object

        subject.create_profile payment
      end
    end

    context 'with an order that does not have a bill address' do
      let(:bill_address) { nil }

      it 'does not store a bill address with the provider' do
        subject.provider.should_receive(:store).with(payment.source, {
          email: email,
          login: login,
        }).and_return stub.as_null_object

        subject.create_profile payment
      end
    end
  end
end
