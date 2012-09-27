module SpreeGateway
  class Engine < Rails::Engine
    engine_name 'spree_gateway'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.gateway.payment_methods", :after => "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods << Spree::Gateway::AuthorizeNetCim
        app.config.spree.payment_methods << Spree::Gateway::AuthorizeNet
        app.config.spree.payment_methods << Spree::Gateway::Eway
        app.config.spree.payment_methods << Spree::Gateway::Linkpoint
        app.config.spree.payment_methods << Spree::Gateway::Moneris
        app.config.spree.payment_methods << Spree::Gateway::PayPal
        app.config.spree.payment_methods << Spree::Gateway::SagePay
        app.config.spree.payment_methods << Spree::Gateway::Beanstream
        app.config.spree.payment_methods << Spree::Gateway::BraintreeGateway
        app.config.spree.payment_methods << Spree::Gateway::Stripe
        app.config.spree.payment_methods << Spree::Gateway::Samurai
        app.config.spree.payment_methods << Spree::Gateway::Worldpay
    end
  end

end
