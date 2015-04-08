require 'spec_helper'

describe Spree::Gateway::StripeGateway do
  let(:secret_key) { 'key' }
  let(:email) { 'customer@example.com' }
  let(:source) { Spree::CreditCard.new }

  let(:payment) {
    double('Spree::Payment',
      source: source,
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
    subject.preferences = { secret_key: secret_key }
    subject.stub(:options_for_purchase_or_auth).and_return(['money','cc','opts'])
    subject.stub(:provider).and_return provider
  end

  describe '#create_profile' do
    before do
      payment.source.stub(:update_attributes!)
    end

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

      # Regression test for #141
      context "correcting the card type" do
        before do
          # We don't care about this method for these tests
          subject.provider.stub(:store).and_return(double.as_null_object)
        end

        it "converts 'American Express' to 'american_express'" do
          payment.source.cc_type = 'American Express'
          subject.create_profile(payment)
          expect(payment.source.cc_type).to eq('american_express')
        end

        it "converts 'Diners Club' to 'diners_club'" do
          payment.source.cc_type = 'Diners Club'
          subject.create_profile(payment)
          expect(payment.source.cc_type).to eq('diners_club')
        end

        it "converts 'Visa' to 'visa'" do
          payment.source.cc_type = 'Visa'
          subject.create_profile(payment)
          expect(payment.source.cc_type).to eq('visa')
        end
      end
    end

    context 'with a card represents payment_profile' do
      let(:source) { Spree::CreditCard.new(gateway_payment_profile_id: 'tok_profileid') }
      let(:bill_address) { nil }

      it 'stores the profile_id as a card' do
        subject.provider.should_receive(:store).with(source.gateway_payment_profile_id, anything).and_return double.as_null_object

        subject.create_profile payment
      end
    end
  end

  context 'purchasing' do
    after do
      subject.purchase(19.99, 'credit card', {})
    end

    it 'send the payment to the provider' do
      provider.should_receive(:purchase).with('money','cc','opts')
    end
  end

  context 'authorizing' do
    after do
      subject.authorize(19.99, 'credit card', {})
    end

    it 'send the authorization to the provider' do
      provider.should_receive(:authorize).with('money','cc','opts')
    end
  end

  context 'capturing' do

    after do
      subject.capture(1234, 'response_code', {})
    end

    it 'convert the amount to cents' do
      provider.should_receive(:capture).with(1234,anything,anything)
    end

    it 'use the response code as the authorization' do
      provider.should_receive(:capture).with(anything,'response_code',anything)
    end
  end

  context 'capture with payment class' do
    let(:gateway) do
      gateway = described_class.new(active: true)
      gateway.set_preference :secret_key, secret_key
      gateway.stub(:options_for_purchase_or_auth).and_return(['money','cc','opts'])
      gateway.stub(:provider).and_return provider
      gateway.stub :source_required => true
      gateway
    end

    let(:order) { Spree::Order.create }

    let(:card) do
      # mock_model(Spree::CreditCard, :gateway_customer_profile_id => 'cus_abcde',
                                    # :imported => false)
      create :credit_card, gateway_customer_profile_id: 'cus_abcde', imported: false
    end

    let(:payment) do
      payment = Spree::Payment.new
      payment.source = card
      payment.order = order
      payment.payment_method = gateway
      payment.amount = 98.55
      payment.state = 'pending'
      payment.response_code = '12345'
      payment
    end

    let!(:success_response) do
      double('success_response', :success? => true,
                               :authorization => '123',
                               :avs_result => { 'code' => 'avs-code' },
                               :cvv_result => { 'code' => 'cvv-code', 'message' => "CVV Result"})
    end

    after do
      payment.capture!
    end

    it 'gets correct amount' do
      provider.should_receive(:capture).with(9855,'12345',anything).and_return(success_response)
    end
  end
end
