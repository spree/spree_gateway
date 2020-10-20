require 'spec_helper'

describe Spree::Gateway::StripeAchGateway do
  let(:secret_key) { 'key' }
  let(:email) { 'customer@example.com' }
  let(:source) { Spree::Check.new }
  let(:payment) {
    double('Spree::Payment',
           source: source,
           order: double('Spree::Order',
                         email: email,
                         bill_address: bill_address,
                         user: double('Spree::User',
                                      email: email)
           )
    )
  }
  let(:provider) do
    double('provider').tap do |p|
      p.stub(:purchase)
      p.stub(:authorize)
      p.stub(:capture)
      p.stub(:verify)
    end
  end

  before do
    subject.preferences = { secret_key: secret_key }
    subject.stub(:options_for_purchase_or_auth).and_return(['money','check','opts'])
    subject.stub(:provider).and_return provider
  end

  describe '#create_profile' do
    before do
      payment.source.stub(:update!)
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
            login: secret_key
        }).and_return double.as_null_object

        subject.create_profile payment
      end

    end

    context 'with a check represents payment_profile' do
      let(:source) { Spree::Check.new(gateway_payment_profile_id: 'tok_profileid') }
      let(:bill_address) { nil }

      it 'stores the profile_id as a check' do
        subject.provider.should_receive(:store).with(source.gateway_payment_profile_id, anything).and_return double.as_null_object

        subject.create_profile payment
      end
    end
  end

  context 'purchasing' do
    after do
      subject.purchase(19.99, 'check', {})
    end

    it 'send the payment to the provider' do
      provider.should_receive(:purchase).with('money', 'check', 'opts')
    end
  end

  context 'authorizing' do
    after do
      subject.authorize(19.99, 'check', {})
    end

    it 'send the authorization to the provider' do
      provider.should_receive(:authorize).with('money', 'check', 'opts')
    end
  end

  context 'verifying' do
    after do
      subject.verify(source, {})
    end

    it 'send the verify to the provider' do
      provider.should_receive(:verify).with(source, anything)
    end
  end

  context 'capturing' do

    after do
      subject.capture(1234, 'response_code', {})
    end

    it 'convert the amount to cents' do
      provider.should_receive(:capture).with(1234, anything, anything)
    end

    it 'use the response code as the authorization' do
      provider.should_receive(:capture).with(anything, 'response_code', anything)
    end
  end

  context 'capture with payment class' do
    let(:gateway) do
      gateway = described_class.new(active: true)
      gateway.set_preference :secret_key, secret_key
      gateway.stub(:options_for_purchase_or_auth).and_return(['money', 'check', 'opts'])
      gateway.stub(:provider).and_return provider
      gateway.stub source_required: true
      gateway
    end

    let(:order) { Spree::Order.create }

    let(:check) do
      # mock_model(Spree::Check, :gateway_customer_profile_id => 'cus_abcde',
      # :imported => false)
      create :check, gateway_customer_profile_id: 'cus_abcde', imported: false
    end

    let(:payment) do
      payment = Spree::Payment.new
      payment.source = check
      payment.order = order
      payment.payment_method = gateway
      payment.amount = 98.55
      payment.state = 'pending'
      payment.response_code = '12345'
      payment
    end

    after do
      payment.capture!
    end

    let!(:success_response) do
      double('success_response',
             success?: true,
             authorization: '123',
             avs_result: { 'code' => 'avs-code' },
             cvv_result: { 'code' => 'cvv-code', 'message' => 'CVV Result' },
             params: {})
    end

    it 'gets correct amount' do
      provider.should_receive(:capture).with(9855, '12345', anything).and_return(success_response)
    end
  end
end
