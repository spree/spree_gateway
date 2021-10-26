# we need to add this route to the root Rails application because Spree can
# be mounted to some path eg. /shop and Apple Pay expects to access this file
# via https://example.com/.well-known/apple-developer-merchantid-domain-association
Rails.application.routes.draw do
  get '/.well-known/apple-developer-merchantid-domain-association' => 'spree/apple_pay_domain_verification#show'
end

Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :storefront do
        namespace :intents do
          post :payment_confirmation_data
          post :handle_response
        end
      end
    end
  end
end
