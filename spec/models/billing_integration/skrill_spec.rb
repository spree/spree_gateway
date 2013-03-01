require 'spec_helper'

describe Spree::BillingIntegration::Skrill::QuickCheckout do
  context "redirect_url" do
    let(:payment_method) { Factory :skrill_quick_checkout }
    let(:order) { Factory(:order) }

    it "should return url" do
      ActiveMerchant::Billing::Skrill.any_instance.should_receive(:setup_payment_session).and_return('123')
      payment_method.redirect_url(order).should == "#{ActiveMerchant::Billing::Skrill.new.service_url}?sid=123"
    end
  end

end
