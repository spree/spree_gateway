require 'spec_helper'

describe Spree::Gateway::BraintreeGateway do

  before(:each) do
    Spree::Gateway.update_all :active => false
    @gateway = Spree::Gateway::BraintreeGateway.create!(:name => "Braintree Gateway", :environment => "sandbox", :active => true)

    @gateway.set_preference(:environment, "sandbox" )
    @gateway.set_preference(:merchant_id, "zbn5yzq9t7wmwx42" )
    @gateway.set_preference(:public_key, "ym9djwqpkxbv3xzt")
    @gateway.set_preference(:private_key, "4ghghkyp2yy6yqc8")
    @gateway.save!

    with_payment_profiles_off do
      @country = FactoryGirl.create(:country, :name => "United States", :iso_name => "UNITED STATES", :iso3 => "USA", :iso => "US", :numcode => 840)
      @state   = FactoryGirl.create(:state, :name => "Maryland", :abbr => "MD", :country => @country)
      @address = FactoryGirl.create(:address,
        :firstname => 'John',
        :lastname => 'Doe',
        :address1 => '1234 My Street',
        :address2 => 'Apt 1',
        :city =>  'Washington DC',
        :zipcode => '20123',
        :phone => '(555)555-5555',
        :state => @state,
        :country => @country
      )
      @order = FactoryGirl.create(:order_with_totals, :bill_address => @address, :ship_address => @address)
      @order.update!
      @credit_card = FactoryGirl.create(:credit_card, :verification_value => '123', :number => '5105105105105100', :month => 9, :year => Time.now.year + 1, :first_name => 'John', :last_name => 'Doe', :cc_type => 'mastercard')
      @payment = FactoryGirl.create(:payment, :source => @credit_card, :order => @order, :payment_method => @gateway, :amount => 10.00)
      @payment.payment_method.environment = "test"
    end

  end

  describe 'merchant_account_id' do
    before do
      @gateway.set_preference(:merchant_account_id, merchant_account_id)
    end

    context "with merchant_account_id empty" do
      let(:merchant_account_id) { "" }

      it 'should not be present in options' do
        @gateway.options.keys.include?(:merchant_account_id).should be_false
      end
    end

    context 'with merchant_account_id set on gateway' do
      let(:merchant_account_id) { 'test' }

      it 'should have a perferred_merchant_account_id' do
        @gateway.preferred_merchant_account_id.should == merchant_account_id
      end

      it 'should have a preferences[:merchant_account_id]' do
        @gateway.preferences.keys.include?(:merchant_account_id).should be_true
      end

      it 'should be present in options' do
        @gateway.options.keys.include?(:merchant_account_id).should be_true
      end
    end
  end

  it "should be braintree gateway" do
    @gateway.provider_class.should == ::ActiveMerchant::Billing::BraintreeBlueGateway
  end

  describe "preferences" do
    it "should not include server + test_mode" do
      lambda { @gateway.preferences.fetch(:server) }.should raise_error(StandardError)
    end
  end

  describe "authorize" do
    it "should return a success response with an authorization code" do
      result = @gateway.authorize(500, @credit_card)

      result.success?.should be_true
      result.authorization.should match(/\A\w{6}\z/)


      Braintree::Transaction::Status::Authorized.should == Braintree::Transaction.find(result.authorization).status
    end

    shared_examples "a valid credit card" do
      it 'should work through the spree payment interface' do
        Spree::Config.set :auto_capture => false
        @payment.log_entries.size.should == 0
        @payment.process!
        @payment.log_entries.size.should == 1
        @payment.response_code.should match /\A\w{6}\z/
        @payment.state.should == 'pending'
        transaction = ::Braintree::Transaction.find(@payment.response_code)
        transaction.status.should == Braintree::Transaction::Status::Authorized
        card_number = @credit_card.number[0..5] + "******" + @credit_card.number[-4..-1]
        transaction.credit_card_details.masked_number.should == card_number
        transaction.credit_card_details.expiration_date.should == "09/#{Time.now.year + 1}"
        transaction.customer_details.first_name.should == 'John'
        transaction.customer_details.last_name.should == 'Doe'
      end
    end

    context "when the card is a mastercard" do
      before do
        @credit_card.number = '5105105105105100'
        @credit_card.cc_type = 'mastercard'
        @credit_card.save
      end

      it_behaves_like "a valid credit card"
    end

    context "when the card is a visa" do
      before do
        @credit_card.number = '4111111111111111'
        @credit_card.cc_type = 'visa'
        @credit_card.save
      end

      it_behaves_like "a valid credit card"
    end

    context "when the card is an amex" do
      before do
        @credit_card.number = '378282246310005'
        @credit_card.verification_value = '1234'
        @credit_card.cc_type = 'amex'
        @credit_card.save
      end

      it_behaves_like "a valid credit card"
    end

    context "when the card is a JCB" do
      before do
        @credit_card.number = '3530111333300000'
        @credit_card.cc_type = 'jcb'
        @credit_card.save
      end

      it_behaves_like "a valid credit card"
    end

    context "when the card is a diners club" do
      before do
        @credit_card.number = '36050000000003'
        @credit_card.cc_type = 'dinersclub'
        @credit_card.save
      end

      it_behaves_like "a valid credit card"
    end
  end

  describe "capture" do

    it " should capture a previous authorization" do
      @payment.process!
      assert_equal 1, @payment.log_entries.size
      assert_match /\A\w{6}\z/, @payment.response_code
      transaction = ::Braintree::Transaction.find(@payment.response_code)
      transaction.status.should == Braintree::Transaction::Status::Authorized
      capture_result = @gateway.capture(@payment,:ignored_arg_credit_card, :ignored_arg_options)
      capture_result.success?.should be_true
      transaction = ::Braintree::Transaction.find(@payment.response_code)
      transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
    end

    pending "raise an error if capture fails using spree interface" do
      Spree::Config.set :auto_capture => false
      @payment.log_entries.size.should == 0
      @payment.process!
      @payment.log_entries.size.should == 1
      transaction = ::Braintree::Transaction.find(@payment.response_code)
      transaction.status.should == Braintree::Transaction::Status::Authorized
      @payment.payment_source.capture(@payment) # as done in PaymentsController#fire
      # transaction = ::Braintree::Transaction.find(@payment.response_code)
      # transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
      # lambda do
      #   @payment.payment_source.capture(@payment)
      # end.should raise_error(Spree::Core::GatewayError, "Cannot submit for settlement unless status is authorized. (91507)")
    end
  end

  describe 'purchase' do
    it 'should return a success response with an authorization code' do
      result =  @gateway.purchase(500, @credit_card)
      result.success?.should be_true
      result.authorization.should match(/\A\w{6}\z/)
      Braintree::Transaction::Status::SubmittedForSettlement.should == Braintree::Transaction.find(result.authorization).status
    end

    it 'should work through the spree payment interface with payment profiles' do
      purchase_using_spree_interface
      transaction = ::Braintree::Transaction.find(@payment.response_code)
      transaction.credit_card_details.token.should_not be_nil
    end

    it 'should work through the spree payment interface without payment profiles' do
        with_payment_profiles_off do
          purchase_using_spree_interface(false)
          transaction = ::Braintree::Transaction.find(@payment.response_code)
          transaction.credit_card_details.token.should be_nil
        end
    end
  end

  describe "credit" do
    pending "should work through the spree interface" do
      @payment.amount += 100.00
      purchase_using_spree_interface
      credit_using_spree_interface
    end
  end

  describe "void" do
    pending "should work through the spree credit_card / payment interface" do
      assert_equal 0, @payment.log_entries.size
      @payment.process!
      assert_equal 1, @payment.log_entries.size
      @payment.response_code.should match(/\A\w{6}\z/)
      transaction = Braintree::Transaction.find(@payment.response_code)
      transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
      @credit_card.void(@payment)
      transaction = Braintree::Transaction.find(transaction.id)
      transaction.status.should == Braintree::Transaction::Status::Voided
    end
  end

  describe "update_card_number" do
    it "passes through gateway_payment_profile_id" do
      credit_card = { 'token' => 'testing', 'last_4' => '1234', 'masked_number' => '5555**5555' }
      @gateway.update_card_number(@payment.source, credit_card)
      @payment.source.gateway_payment_profile_id.should == "testing"
    end
  end

  def credit_using_spree_interface
    @payment.log_entries.size.should == 1
    @payment.source.credit(@payment) # as done in PaymentsController#fire
    @payment.log_entries.size.should == 2
    #Let's get the payment record associated with the credit
    @payment = @order.payments.last
    @payment.response_code.should match(/\A\w{6}\z/)
    transaction = ::Braintree::Transaction.find(@payment.response_code)
    transaction.type.should == Braintree::Transaction::Type::Credit
    transaction.status.should == Braintree::Transaction::Status::SubmittedForSettlement
    transaction.credit_card_details.masked_number.should == "510510******5100"
    transaction.credit_card_details.expiration_date.should == "09/#{Time.now.year + 1}"
    transaction.customer_details.first_name.should == "John"
    transaction.customer_details.last_name.should == "Doe"
  end

  def purchase_using_spree_interface(profile=true)
    Spree::Config.set :auto_capture => true
    @payment.send(:create_payment_profile) if profile
    @payment.log_entries.size == 0
    @payment.process! # as done in PaymentsController#create
    @payment.log_entries.size == 1
    @payment.response_code.should match /\A\w{6}\z/
    @payment.state.should == 'completed'
    transaction = ::Braintree::Transaction.find(@payment.response_code)
    Braintree::Transaction::Status::SubmittedForSettlement.should == transaction.status
    transaction.credit_card_details.masked_number.should == "510510******5100"
    transaction.credit_card_details.expiration_date.should == "09/#{Time.now.year + 1}"
    transaction.customer_details.first_name.should == 'John'
    transaction.customer_details.last_name.should == 'Doe'
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
