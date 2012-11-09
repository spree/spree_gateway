require 'spec_helper'

describe Spree::Gateway::Banwire do
  let(:gateway){ Spree::Gateway::Banwire.create!(name: "Banwire") }
end
