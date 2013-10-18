require 'spec_helper'

describe Spree::Gateway::PayflowPro do
  let (:gateway) { Spree::Gateway::PayflowPro.create!(:name => "PayflowPro") }

  describe "options" do
    it "should include :test => true when :test_mode is true" do
      gateway.preferred_test_mode = true
      gateway.options[:test].should == true
    end

    it "should not include :test when test_mode is false" do
      gateway.preferred_test_mode = false
      gateway.options[:test].should == false
    end
  end
end
