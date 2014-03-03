require 'spec_helper'

describe Spree::SkrillTransaction do
  let(:skrill_transaction) { create(:skrill_transaction) }

  context '.actions' do
    it { expect(subject.actions).to match_array([]) }
  end
end