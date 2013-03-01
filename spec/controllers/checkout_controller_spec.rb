require 'spec_helper'

describe Spree::CheckoutController do
  let(:skrill_gateway) { BillingIntegration::Skrill::QuickCheckout.new :id => 123, :preferred_merchant_id => '987654321' }
  let(:order) { Factory(:order, :state => "payment") }

  before do
    controller.stub(:current_order => order, :check_authorization => true, :current_user => order.user)
    order.stub(:checkout_allowed? => true, :completed? => false)
    order.update!
  end

  it "should understand skrill routes" do
    assert_routing("/orders/#{order.number}/checkout/skrill_success", {:controller => "checkout", :action => "skrill_success", :order_id => order.number })
    assert_routing("/orders/#{order.number}/checkout/skrill_cancel", {:controller => "checkout", :action => "skrill_cancel", :order_id => order.number })
  end

  context "during payment selection on checkout" do
    it "should setup a purchase transaction and redirect" do
      PaymentMethod.should_receive(:find).at_least(1).with("123").and_return(skrill_gateway)
      ActiveMerchant::Billing::Skrill.any_instance.should_receive(:setup_payment_session).and_return('abc123')
      post :update, {:order_id => order.number, :state => 'payment', :order => {:payments_attributes => [:payment_method_id => "123" ] } }

      response.should redirect_to 'https://www.moneybookers.com/app/payment.pl?sid=abc123'

      order.payments.size.should == 1
      order.payments.first.source_type.should == 'SkrillAccount'
      order.payments.first.pending?.should be_true
    end

  end

  context "with response from Skrill" do
    before { Factory(:payment, :order_id => order.id, :source => SkrillAccount.find_or_create_by_email(order.email)) }

    it "should redirect to cart on cancel" do
      get :skrill_cancel, :order_id => order.number

      response.should redirect_to edit_order_url(order)
    end

    it "should complete order on first success" do
      Order.should_receive(:where).with(:number => order.number).and_return([order])

      order.state.should == 'payment'
      get :skrill_success, :order_id => order.number
      order.state.should == 'complete'

      order.completed_at.should_not be_nil

      response.should redirect_to order_path(order)
    end
  end

end

