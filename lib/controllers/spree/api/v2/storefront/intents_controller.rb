module Spree
  module Api
    module V2
      module Storefront
        class IntentsController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2::Storefront::OrderConcern

          def handle_response
            if params['response']['error']
              invalidate_payment
              render_error_payload(params['response']['error']['message'])
            else
              render_serialized_payload { { message: I18n.t('spree.payment_successfully_authorized') } }
            end
          end

          private

          def invalidate_payment
            payment = spree_current_order.payments.find_by!(response_code: params['response']['error']['payment_intent']['id'])
            payment.update(state: 'failed', intent_client_key: nil)
          end
        end
      end
    end
  end
end
