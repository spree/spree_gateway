require 'spec_helper'

describe Spree::Gateway::StripeGateway do
  let(:payment) {
    stub('Spree::Payment',
      order: stub('Spree::Order', bill_address: bill_address)
    )
  }

  describe '#address_for' do
    context 'order with bill address' do
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

      it 'returns the bill address from the order' do
        expect(subject.address_for payment).to eq({
          address: {
            address1: '123 Happy Road',
            address2: 'Apt 303',
            city: 'Suzarac',
            zip: '95671',
            state: 'Oregon',
            country: 'United States'
          }
        })
      end
    end

    context 'order without a bill address' do
      let(:bill_address) { nil }

      it 'returns an empty hash' do
        expect(subject.address_for payment).to eq({})
      end
    end
  end
end
