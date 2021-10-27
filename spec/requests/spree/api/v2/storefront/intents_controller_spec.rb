require 'spec_helper'

describe 'Storefront API v2 Account spec', type: :request do
  include_context 'API v2 tokens'

  let!(:user)  { create(:user_with_addresses) }
  let(:headers) { headers_bearer }

  describe '#payment_confirmation_data' do
    subject :post_payment_confirmation_data do
      post '/api/v2/storefront/intents/payment_confirmation_data', params: params, headers: headers_bearer
    end

    include_context 'API v2 tokens'
  end
end