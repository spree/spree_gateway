require 'spec_helper'

describe Savon do
  let(:config) { Savon.config }

  it 'does not log anything' do
    expect(Savon.config.logger).to be_a_kind_of Savon::NullLogger
  end
end
