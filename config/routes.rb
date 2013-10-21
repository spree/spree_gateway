routes = lambda do
  # Add your extension routes here
  resources :orders do
    resource :checkout, :controller => 'checkout' do
      member do
        get :skrill_cancel
        get :skrill_return
      end
    end
  end

  post '/skrill' => 'skrill_status#update'
end


if Spree::Core::Engine.respond_to?(:add_routes)
  Spree::Core::Engine.add_routes(&routes)
else
  Spree::Core::Engine.routes.prepend(&routes)
end
