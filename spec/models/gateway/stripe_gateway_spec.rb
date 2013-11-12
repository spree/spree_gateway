require 'spec_helper'

describe Spree::Gateway::StripeGateway do
  let(:secret_key) { 'key' }
  let(:email) { 'customer@example.com' }

  let(:payment) {
    double('Spree::Payment',
      source: double('Source', gateway_customer_profile_id: nil).as_null_object,
      order: double('Spree::Order',
        email: email,
        bill_address: bill_address
      )
    )
  }

  let(:provider) do
    double('provider').tap do |p|
      p.stub(:purchase)
      p.stub(:authorize)
      p.stub(:capture)
    end
  end

  before do 
    subject.set_preference :secret_key, secret_key
    subject.stub(:options_for_purchase_or_auth).and_return(['money','cc','opts'])
    subject.stub(:provider).and_return provider
  end

  describe '#create_profile' do
    context 'with an order that has a bill address' do
      let(:bill_address) {
        double('Spree::Address',
          address1: '123 Happy Road',
          address2: 'Apt 303',
          city: 'Suzarac',
          zipcode: '95671',
          state: double('Spree::State', name: 'Oregon'),
          country: double('Spree::Country', name: 'United States')
        )
      }

      it 'stores the bill address with the provider' do
        subject.provider.should_receive(:store).with(payment.source, {
          email: email,
          login: secret_key,

          address: {
            address1: '123 Happy Road',
            address2: 'Apt 303',
            city: 'Suzarac',
            zip: '95671',
            state: 'Oregon',
            country: 'United States'
          }
        }).and_return double.as_null_object

        subject.create_profile payment
      end
    end

    context 'with an order that does not have a bill address' do
      let(:bill_address) { nil }

      it 'does not store a bill address with the provider' do
        subject.provider.should_receive(:store).with(payment.source, {
          email: email,
          login: secret_key,
        }).and_return double.as_null_object

        subject.create_profile payment
      end
    end
  end

  context 'purchasing' do

    after(:each) do
      subject.purchase(19.99, 'credit card', {})
    end

    it 'should send the payment to the provider' do
      provider.should_receive(:purchase).with('money','cc','opts')
    end

  end

  context 'authorizing' do

    after(:each) do
      subject.authorize(19.99, 'credit card', {})
    end

    it 'should send the authorization to the provider' do
      provider.should_receive(:authorize).with('money','cc','opts')
    end

  end

  context 'capturing' do

    let(:payment) do
      double('payment').tap do |p|
        p.stub(:amount).and_return(12.34)
        p.stub(:response_code).and_return('response_code')
      end
    end 

    after(:each) do
      subject.capture(payment, 'credit card', {})
    end

    it 'should convert the amount to cents' do
      provider.should_receive(:capture).with(1234,anything,anything)
    end

    it 'should use the response code as the authorization' do
      provider.should_receive(:capture).with(anything,'response_code',anything)
    end
  end
end
