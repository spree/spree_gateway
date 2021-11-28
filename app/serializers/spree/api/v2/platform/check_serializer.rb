module Spree
  module Api
    module V2
      module Platform
        class CheckSerializer < BaseSerializer
          include ResourceSerializerConcern

          belongs_to :user
          belongs_to :payment_method
        end
      end
    end
  end
end
