require 'spec_helper'

describe Spree::Gateway::BraintreeGateway do

  before do
    Spree::Gateway.update_all(active: false)
    @gateway = Spree::Gateway::BraintreeGateway.create!(name: 'Braintree Gateway', environment: 'sandbox', active: true)
    @gateway.set_preference(:environment, 'sandbox')
    @gateway.set_preference(:merchant_id, 'zbn5yzq9t7wmwx42')
    @gateway.set_preference(:public_key,  'ym9djwqpkxbv3xzt')
    @gateway.set_preference(:private_key, '4ghghkyp2yy6yqc8')
    @gateway.save!

    with_payment_profiles_off do
      country = create(:country, name: 'United States', iso_name: 'UNITED STATES', iso3: 'USA', iso: 'US', numcode: 840)
      state   = create(:state, name: 'Maryland', abbr: 'MD', country: country)
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

      order = create(:order_with_totals, bill_address: address, ship_address: address)
      order.update!

      @credit_card = create(:credit_card,
        verification_value: '123',
        number:             '5105105105105100',
        month:              9,
        year:               Time.now.year + 1,
        first_name:         'John',
        last_name:          'Doe',
        cc_type:            'mastercard')

      @payment = create(:payment, source: @credit_card, order: order, payment_method: @gateway, amount: 10.00)
      @payment.payment_method.environment = 'test'
    end
  end

  describe 'merchant_account_id' do
    before do
      @gateway.set_preference(:merchant_account_id, merchant_account_id)
    end

    context 'with merchant_account_id empty' do
      let(:merchant_account_id) { '' }

      it 'does not be present in options' do
        expect(@gateway.options.keys.include?(:merchant_account_id)).to be_false
      end
    end

    context 'with merchant_account_id set on gateway' do
      let(:merchant_account_id) { 'test' }

      it 'have a perferred_merchant_account_id' do
        expect(@gateway.preferred_merchant_account_id).to eq merchant_account_id
      end

      it 'have a preferences[:merchant_account_id]' do
        expect(@gateway.preferences.keys.include?(:merchant_account_id)).to be_true
      end

      it 'is present in options' do
        expect(@gateway.options.keys.include?(:merchant_account_id)).to be_true
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
      expect(@gateway.payment_profiles_supported?).to be_true
    end
  end

  context 'preferences' do
    it 'does not include server + test_mode' do
      expect { @gateway.preferences.fetch(:server) }.to raise_error(StandardError)
    end
  end

  describe 'authorize' do
    it 'return a success response with an authorization code' do
      result = @gateway.authorize(500, @credit_card)

      expect(result.success?).to be_true
      expect(result.authorization).to match /\A\w{6}\z/
      expect(Braintree::Transaction::Status::Authorized).to eq Braintree::Transaction.find(result.authorization).status
    end

    shared_examples 'a valid credit card' do
      it 'work through the spree payment interface' do
        Spree::Config.set auto_capture: false
        expect(@payment.log_entries.size).to eq(0)

        @payment.process!
        expect(@payment.log_entries.size).to eq(1)
        expect(@payment.response_code).to match /\A\w{6}\z/
        expect(@payment.state).to eq 'pending'

        transaction = ::Braintree::Transaction.find(@payment.response_code)
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
        @credit_card.number = '5105105105105100'
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
      expect(@payment.response_code).to match /\A\w{6}\z/

      transaction = ::Braintree::Transaction.find(@payment.response_code)
      expect(transaction.status).to eq Braintree::Transaction::Status::Authorized

      capture_result = @gateway.capture(@payment,:ignored_arg_credit_card, :ignored_arg_options)
      expect(capture_result.success?).to be_true

      transaction = ::Braintree::Transaction.find(@payment.response_code)
      expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement
    end

    it 'raise an error if capture fails using spree interface' do
      Spree::Config.set(auto_capture: false)
      expect(@payment.log_entries.size).to eq(0)

      @payment.process!
      expect(@payment.log_entries.size).to eq(1)

      transaction = ::Braintree::Transaction.find(@payment.response_code)
      expect(transaction.status).to eq Braintree::Transaction::Status::Authorized

      pending 'undefined method reopen for nil:NilClass'
      @payment.payment_source.capture(@payment) # as done in PaymentsController#fire
      transaction = ::Braintree::Transaction.find(@payment.response_code)
      expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement
      expect {
        @payment.payment_source.capture(@payment)
      }.to raise_error(Spree::Core::GatewayError, 'Cannot submit for settlement unless status is authorized. (91507)')
    end
  end

  context 'purchase' do
    it 'return a success response with an authorization code' do
      result =  @gateway.purchase(500, @credit_card)
      expect(result.success?).to be_true
      expect(result.authorization).to match /\A\w{6}\z/
      expect(Braintree::Transaction::Status::SubmittedForSettlement).to eq Braintree::Transaction.find(result.authorization).status
    end

    it 'work through the spree payment interface with payment profiles' do
      purchase_using_spree_interface
      transaction = ::Braintree::Transaction.find(@payment.response_code)
      expect(transaction.credit_card_details.token).not_to be_nil
    end

    it 'work through the spree payment interface without payment profiles' do
      with_payment_profiles_off do
        purchase_using_spree_interface(false)
        transaction = ::Braintree::Transaction.find(@payment.response_code)
        expect(transaction.credit_card_details.token).to be_nil
      end
    end
  end

  context 'credit' do
    it 'work through the spree interface' do
      pending 'undefined method credit for #<TestCard:0x007fdba1809ad8>'
      @payment.amount += 100.00
      purchase_using_spree_interface
      credit_using_spree_interface
    end
  end

  context 'void' do
    it 'work through the spree credit_card / payment interface' do
      expect(@payment.log_entries.size).to eq(0)
      @payment.process!

      expect(@payment.log_entries.size).to eq(1)
      expect(@payment.response_code).to match /\A\w{6}\z/

      pending 'expected: submitted_for_settlement got: authorized'
      transaction = Braintree::Transaction.find(@payment.response_code)
      expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement

      @credit_card.void(@payment)
      transaction = Braintree::Transaction.find(transaction.id)
      expect(transaction.status).to eq Braintree::Transaction::Status::Voided
    end
  end

  context 'update_card_number' do
    it 'passes through gateway_payment_profile_id' do
      credit_card = { 'token' => 'testing', 'last_4' => '1234', 'masked_number' => '5555**5555' }
      @gateway.update_card_number(@payment.source, credit_card)
      expect(@payment.source.gateway_payment_profile_id).to eq 'testing'
    end
  end

  def credit_using_spree_interface
    expect(@payment.log_entries.size).to eq(1)
    @payment.source.credit(@payment) # as done in PaymentsController#fire
    expect(@payment.log_entries.size).to eq(2)

    # Let's get the payment record associated with the credit
    @payment = @order.payments.last
    expect(@payment.response_code).to match /\A\w{6}\z/

    transaction = ::Braintree::Transaction.find(@payment.response_code)
    expect(transaction.type).to eq Braintree::Transaction::Type::Credit
    expect(transaction.status).to eq Braintree::Transaction::Status::SubmittedForSettlement
    expect(transaction.credit_card_details.masked_number).to eq '510510******5100'
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
    expect(@payment.response_code).to match /\A\w{6}\z/
    expect(@payment.state).to eq 'completed'

    transaction = ::Braintree::Transaction.find(@payment.response_code)
    expect(Braintree::Transaction::Status::SubmittedForSettlement).to eq transaction.status
    expect(transaction.credit_card_details.masked_number).to eq '510510******5100'
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
