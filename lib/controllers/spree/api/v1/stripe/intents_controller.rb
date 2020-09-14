module Spree
  module Api
    module V1
      module Stripe
        class IntentsController < ::ActionController::API
          def handle_response
            @order = Spree::Order.incomplete.find_by!(token: params['order_token'])
            if params['response']['error']
              render json: { errors: params['response']['error']['message'] }, status: 422
            else
              render json: {}, status: :ok
            end
          end
        end
      end
    end
  end
end
