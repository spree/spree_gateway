require 'spec_helper'

describe ActiveMerchant::Billing::Skrill do
  let(:url) { 'https://www.moneybookers.com/app/payment.pl' }

  context '.service_url' do
    it 'return its url' do
      expect(subject.service_url).to eq url
    end
  end

  context '.payment_url' do
    it 'prepend options to url' do
      options = { 'hi' => 'you' }
      expect(subject.payment_url(options)).to eq "#{url}?hi=you"
    end
  end
end