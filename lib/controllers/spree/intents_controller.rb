module Spree
  class IntentsController < ::ActionController::Base
    skip_before_action :verify_authenticity_token

    def handle_response
      binding.pry
    end
  end
end
