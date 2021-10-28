require 'spec_helper'

describe Spree::Api::V2::Platform::CheckSerializer do
  include_context 'API v2 serializers params'

  subject { described_class.new(resource, params: serializer_params) }

  let(:resource) { create(:check, user: create(:user)) }

  it { expect(subject.serializable_hash).to be_kind_of(Hash) }

  it do
    expect(subject.serializable_hash).to eq(
      {
        data: {
          id: resource.id.to_s,
          type: :check,
          attributes: {
            account_holder_name: resource.account_holder_name,
            account_holder_type: resource.account_holder_type,
            routing_number: resource.routing_number,
            account_number: resource.account_number,
            account_type: resource.account_type,
            status: resource.status,
            last_digits: resource.last_digits,
            created_at: resource.created_at,
            updated_at: resource.updated_at,
            deleted_at: resource.deleted_at,
          },
          relationships: {
            user: {
              data: {
                id: resource.user.id.to_s,
                type: :user
              }
            },
            payment_method: {
              data: {
                id: resource.payment_method.id.to_s,
                type: :payment_method
              }
            },
          }
        }
      }
    )
  end
end
