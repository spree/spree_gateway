require 'spec_helper'

describe Savon do
  let(:config) { Savon.config }

  it "should not log anything" do
    Savon.config.logger.should be_a_kind_of(Savon::NullLogger)
  end
end
