require 'spec_helper'
require 'pry'

describe Spree::Gateway::BraintreeGateway do
  before do
    country = Spree::Country.find_by(name: 'United States of America')
    country.update(name: 'United States', iso_name: 'UNITED STATES', iso3: 'USA', iso: 'US', numcode: 840)
    state = create(:state, name: 'Maryland', abbr: 'MD', country: country)
    @address = create(:address,
                     firstname: 'John',
                     lastname:  'Doe',
                     address1:  '1234 My Street',
                     address2:  'Apt 1',
                     city:      'Washington DC',
                     zipcode:   '20123',
                     phone:     '(555)555-5555',
                     state:     state,
                     country:   country)


    Spree::Gateway.update_all(active: false)
    @gateway = Spree::Gateway::BraintreeGateway.create!(name: 'Braintree Gateway', active: true, stores: [::Spree::Store.default])
    @gateway.preferences = {
      environment: 'sandbox',
      merchant_id: 'zbn5yzq9t7wmwx42',
      public_key: 'ym9djwqpkxbv3xzt',
      private_key: '4ghghkyp2yy6yqc8'
    }
    @gateway.save!

    with_payment_profiles_off do
      order = create(:order_with_totals, bill_address: @address, ship_address: @address)
      order.update_with_updater!

      # Use a valid CC from braintree sandbox: https://www.braintreepayments.com/docs/ruby/reference/sandbox

      @credit_card = create(:credit_card,
        verification_value: '123',
        number:             '5555555555554444',
        month:              9,
        year:               Time.now.year + 1,
        name:               'John Doe',
        cc_type:            'mastercard')

      @payment = create(:payment, source: @credit_card, order: order, payment_method: @gateway, amount: 10.00)
    end
  end

  describe 'payment profile creation' do
    before do
      order = create(:order_with_totals, bill_address: @address, ship_address: @address)
      order.update_with_updater!

      @credit_card = create(:credit_card,
        verification_value: '123',
        number:             '5555555555554444',
        month:              9,
        year:               Time.now.year + 1,
        name:               'John Doe',
        cc_type:            'mastercard')

      @payment = create(:payment, source: @credit_card, order: order, payment_method: @gateway, amount: 10.00)
    end

    context 'when a credit card is created' do
      it 'it has the address associated on the remote payment profile' do
        remote_customer = @gateway.provider.instance_variable_get(:@braintree_gateway).customer.find(@credit_card.gateway_customer_profile_id)
        remote_address = remote_customer.addresses.first rescue nil
        expect(remote_address).not_to be_nil
        expect(remote_address.street_address).to eq(@address.address1)
        expect(remote_address.extended_address).to eq(@address.address2)
        expect(remote_address.locality).to eq(@address.city)
        expect(remote_address.region).to eq(@address.state.name)
        expect(remote_address.country_code_alpha2).to eq(@address.country.iso)
        expect(remote_address.postal_code).to eq(@address.zipcode)
      end
    end

  end

  describe 'payment profile failure' do
    before do
      country = Spree::Country.default
      state   = country.states.first
      address = create(:address,
        firstname: 'John',
        lastname:  'Doe',
        address1:  '1234 My Street',
        address2:  'Apt 1',
        city:      'Washington DC',
        zipcode:   '20123',
        phone:     '(555)555-5555',
        state:     state,
        country:   country
      )
      @address = address

      @order = create(:order_with_totals, bill_address: address, ship_address: address)
      @order.update_with_updater!

      @credit_card = create(:credit_card,
        verification_value: '123',
        number:             '5105105105105100',
        month:              9,
        year:               Time.now.year + 1,
        name:               'John Doe',
        cc_type:            'mastercard')
    end

    it 'should fail creation' do
      expect{ create(:payment, source: @credit_card, order: @order, payment_method: @gateway, amount: 10.00) }.to raise_error Spree::Core::GatewayError
    end

  end

  describe 'merchant_account_id' do
    before do
      @gateway.preferences[:merchant_account_id] = merchant_account_id
    end

    context 'with merchant_account_id empty' do
      let(:merchant_account_id) { '' }

      it 'does not be present in options' do
        expect(@gateway.options.keys.include?(:merchant_account_id)).to be false
      end
    end

    context 'with merchant_account_id set on gateway' do
      let(:merchant_account_id) { 'test' }

      it 'have a perferred_merchant_account_id' do
        expect(@gateway.preferred_merchant_account_id).to eq merchant_account_id
      end

      it 'have a preferences[:merchant_account_id]' do
        expect(@gateway.preferences.keys.include?(:merchant_account_id)).to be true
      end

      it 'is present in options' do
        expect(@gateway.options.keys.include?(:merchant_account_id)).to be true
      end
    end
  end

  context '.provider_class' do
    it 'is a BraintreeBlue gateway' do
      expect(@gateway.provider_class).to eq ::ActiveMerchant::Billing::BraintreeBlueGateway
    end
  end

  context '.payment_profiles_supported?' do
    it 'return true' do
      expect(@gateway.payment_profiles_supported?).to be true
    end
  end

  context 'preferences' do
    it 'does not include server + test_mode' do
      expect { @gateway.preferences.fetch(:server) }.to raise_error(StandardError)
    end
  end

  describe 'authorize' do
    context "the credit card has a token" do
      before(:each) do
        @credit_card.update(gateway_payment_profile_id: 'test')
      end

      it 'calls provider#authorize using the gateway_payment_profile_id' do
        expect(@gateway.provider).to receive(:authorize).with(500, 'test', { payment_method_token: true } )
        @gateway.authorize(500, @credit_card)
      end
    end

    context "the given credit card does not have a token" do
      context "the credit card has a customer profile id" do
        before(:each) do
          @credit_card.update(gateway_customer_profile_id: '12345')
        end

        it 'calls provider#authorize using the gateway_customer_profile_id' do
          expect(@gateway.provider).to receive(:authorize).with(500, '12345', {})
          @gateway.authorize(500, @credit_card)
        end
      end

      context "no customer profile id" do
        it 'calls provider#authorize with the credit card object' do
          expect(@gateway.provider).to receive(:authorize).with(500, @credit_card, {})
          @gateway.authorize(500, @credit_card)
        end
      end
    end

    it 'return a success response with an authorization code' do
      result = @gateway.authorize(500, @credit_card)

      expect(result.success?).to be true
      expect(result.authorization).to match /\A\w{6,}\z/
      expect(Braintree::Transaction::Status::Authorized).to eq Braintree::Transaction.find(result.authorization).status
    end

    shared_examples 'a valid credit card' do
      it 'work through the spree payment interface' do
        Spree::Config.set auto_capture: false
        expect(@payment.log_entries.size).to eq(0)

        @payment.process!
        expect(@payment.log_entries.size).to eq(1)
        expect(@payment.transaction_id).to match /\A\w{6,}\z/
        expect(@payment.state).to eq 'pending'

        transaction = ::Braintree::Transaction.find(@payment.transaction_id)
        expect(transaction.status).to eq Braintree::Transaction::Status::Authorized

        card_number = @credit_card.number[0..5] + '******' + @credit_card.number[-4..-1]
        expect(transaction.credit_card_details.masked_number).to eq card_number
        expect(transaction.credit_card_details.expiration_date).to eq "09/#{Time.now.year + 1}"
        expect(transaction.customer_details.first_name).to eq 'John'
        expect(transaction.customer_details.last_name).to eq 'Doe'
      end
    end

    context 'when the card is a mastercard' do
      before do
        @credit_card.number = '5555555555554444'
        @credit_card.cc_type = 'mastercard'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is a visa' do
      before do
        @credit_card.number = '4111111111111111'
        @credit_card.cc_type = 'visa'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is an amex' do
      before do
        @credit_card.number = '378282246310005'
        @credit_card.verification_value = '1234'
        @credit_card.cc_type = 'amex'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is a JCB' do
      before do
        @credit_card.number = '3530111333300000'
        @credit_card.cc_type = 'jcb'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end

    context 'when the card is a diners club' do
      before do
        @credit_card.number = '36050000000003'
        @credit_card.cc_type = 'dinersclub'
        @credit_card.save
      end

      it_behaves_like 'a valid credit card'
    end
  end

  describe 'capture' do
    it 'do capture a previous authorization' do
      @payment.process!
      expect(@payment.log_entries.size).to eq(1)
      expect(@payment.transaction_id).to match /\A\w{6,}\z/

      transaction = ::Braintree::Transaction.find(@payment.transaction_id)
      expect(transaction.status).to eq Braintree::Transaction::Status::Authorized

      capture_result = @gateway.capture(@payment.amount, @payment.transaction_id)
      expect(capture_result.success?).to be true

      transaction = ::Braintree::Transaction.find(@payment.transaction_id)
      expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement
    end

    it 'raise an error if capture fails using spree interface' do
      Spree::Config.set(auto_capture: false)
      expect(@payment.log_entries.size).to eq(0)

      @payment.process!
      expect(@payment.log_entries.size).to eq(1)

      transaction = ::Braintree::Transaction.find(@payment.transaction_id)
      expect(transaction.status).to eq Braintree::Transaction::Status::Authorized

      @payment.capture! # as done in PaymentsController#fire
      transaction = ::Braintree::Transaction.find(@payment.transaction_id)
      expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement
      expect(@payment.completed?).to be true
    end
  end

  context 'purchase' do
    it 'return a success response with an authorization code' do
      result =  @gateway.purchase(500, @credit_card)
      expect(result.success?).to be true
      expect(result.authorization).to match /\A\w{6,}\z/
      expect(Braintree::Transaction::Status::SubmittedForSettlement).to eq Braintree::Transaction.find(result.authorization).status
    end

    it 'work through the spree payment interface with payment profiles' do
      purchase_using_spree_interface
      transaction = ::Braintree::Transaction.find(@payment.transaction_id)
      expect(transaction.credit_card_details.token).not_to be_nil
    end

    it 'work through the spree payment interface without payment profiles' do
      with_payment_profiles_off do
        purchase_using_spree_interface(false)
        transaction = ::Braintree::Transaction.find(@payment.transaction_id)
        expect(transaction.credit_card_details.token).to be_nil
      end
    end
  end

  context 'credit' do
    it 'work through the spree interface' do
      @payment.amount += 100.00
      purchase_using_spree_interface
      skip "Braintree does not provide a way to settle a transaction manually: https://twitter.com/braintree/status/446099537224933376"
      credit_using_spree_interface
    end
  end

  context 'void' do
    before do
      Spree::Config.set(auto_capture: true)
    end

    it 'work through the spree credit_card / payment interface' do
      expect(@payment.log_entries.size).to eq(0)
      @payment.process!

      expect(@payment.log_entries.size).to eq(1)
      expect(@payment.transaction_id).to match /\A\w{6,}\z/

      transaction = Braintree::Transaction.find(@payment.transaction_id)
      expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement

      @payment.void_transaction!
      transaction = Braintree::Transaction.find(transaction.id)
      expect(transaction.status).to eq Braintree::Transaction::Status::Voided
    end
  end

  context 'update_card_number' do
    it 'passes through gateway_payment_profile_id' do
      credit_card = { 'token' => 'testing', 'last_4' => '1234', 'masked_number' => '555555******4444' }
      @gateway.update_card_number(@payment.source, credit_card)
      expect(@payment.source.gateway_payment_profile_id).to eq 'testing'
    end
  end

  def credit_using_spree_interface
    expect(@payment.log_entries.size).to eq(1)
    @payment.credit!
    expect(@payment.log_entries.size).to eq(2)

    # Let's get the payment record associated with the credit
    @payment = @order.payments.last
    expect(@payment.transaction_id).to match /\A\w{6,}\z/

    transaction = ::Braintree::Transaction.find(@payment.transaction_id)
    expect(transaction.type).to eq Braintree::Transaction::Type::Credit
    expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement
    expect(transaction.credit_card_details.masked_number).to eq '555555******4444'
    expect(transaction.credit_card_details.expiration_date).to eq "09/#{Time.now.year + 1}"
    expect(transaction.customer_details.first_name).to eq 'John'
    expect(transaction.customer_details.last_name).to eq 'Doe'
  end

  def purchase_using_spree_interface(profile=true)
    Spree::Config.set(auto_capture: true)
    @payment.send(:create_payment_profile) if profile
    @payment.log_entries.size == 0
    @payment.process! # as done in PaymentsController#create
    @payment.log_entries.size == 1
    expect(@payment.transaction_id).to match /\A\w{6,}\z/
    expect(@payment.state).to eq 'completed'

    transaction = ::Braintree::Transaction.find(@payment.transaction_id)
    expect(Braintree::Transaction::Status::SubmittedForSettlement).to eq transaction.status
    expect(transaction.credit_card_details.masked_number).to eq '555555******4444'
    expect(transaction.credit_card_details.expiration_date).to eq "09/#{Time.now.year + 1}"
    expect(transaction.customer_details.first_name).to eq 'John'
    expect(transaction.customer_details.last_name).to eq 'Doe'
  end

  def with_payment_profiles_off(&block)
    Spree::Gateway::BraintreeGateway.class_eval do
      def payment_profiles_supported?
        false
      end
    end
    yield
  ensure
    Spree::Gateway::BraintreeGateway.class_eval do
      def payment_profiles_supported?
        true
      end
    end
  end
end
