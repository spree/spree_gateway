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
        app.config.spree.payment_methods << Spree::Gateway::CardSave
        app.config.spree.payment_methods << Spree::Gateway::Eway
        app.config.spree.payment_methods << Spree::Gateway::Fatzebra
        app.config.spree.payment_methods << Spree::Gateway::Linkpoint
        app.config.spree.payment_methods << Spree::Gateway::Moneris
        app.config.spree.payment_methods << Spree::Gateway::PayJunction
        app.config.spree.payment_methods << Spree::Gateway::PayPalGateway
        app.config.spree.payment_methods << Spree::Gateway::SagePay
        app.config.spree.payment_methods << Spree::Gateway::Beanstream
        app.config.spree.payment_methods << Spree::Gateway::BraintreeGateway
        app.config.spree.payment_methods << Spree::Gateway::StripeGateway
        app.config.spree.payment_methods << Spree::Gateway::Samurai
        app.config.spree.payment_methods << Spree::Gateway::Worldpay
        app.config.spree.payment_methods << Spree::Gateway::Banwire
        app.config.spree.payment_methods << Spree::Gateway::UsaEpay
        app.config.spree.payment_methods << Spree::BillingIntegration::Skrill::QuickCheckout
        app.config.spree.payment_methods << Spree::Gateway::BalancedGateway
        app.config.spree.payment_methods << Spree::Gateway::DataCash
        app.config.spree.payment_methods << Spree::Gateway::UsaEpay
        app.config.spree.payment_methods << Spree::Gateway::PinGateway
        app.config.spree.payment_methods << Spree::Gateway::Paymill
        app.config.spree.payment_methods << Spree::Gateway::PayflowPro
        app.config.spree.payment_methods << Spree::Gateway::SecurePayAU
    end
  end

end
