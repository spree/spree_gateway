require 'spec_helper'

describe Spree::Gateway::StripeAchGateway do
  let(:secret_key) { 'key' }
  let(:user) { create(:user, email: 'customer@example.com') }
  let(:order) { create(:order, email: user.email, user_id: user.id) }
  let(:source) { Spree::CreditCard.new }
  let(:payment) do
    double('Spree::Payment',
           source: source,
           order: order)
  end


  let(:provider) do
    double('provider').tap do |p|
      p.stub(:verify)
      p.stub(:authorize)
      p.stub(:purchase)
      p.stub(:capture)
    end
  end

  before do
    subject.preferences = { secret_key: secret_key }
    subject.stub(:options_for_purchase_or_auth).and_return(['money','cc','opts'])
    subject.stub(:provider).and_return provider
  end

  describe '#create_profile' do
    before do
      payment.source.stub(:update!)
    end

    context 'with an order that has a bill address' do
      it 'stores the bill address with the provider' do
        subject.provider.should_receive(:store).with(payment.source, {
            email: user.email,
            login: secret_key,

            address: {
                address1: order.bill_address.address1,
                address2: order.bill_address.address2,
                city: order.bill_address.city,
                zip: order.bill_address.zipcode,
                state: order.bill_address.state.name,
                country: order.bill_address.country.name
            }
        }).and_return double.as_null_object

        subject.create_profile payment
      end
    end

    context 'with an order that does not have a bill address' do
      before { order.update(bill_address: nil) }

      it 'does not store a bill address with the provider' do
        subject.provider.should_receive(:store).with(payment.source, {
            email: user.email,
            login: secret_key
        }).and_return double.as_null_object

        subject.create_profile payment
      end
    end
  end
end
