module SpreeGateway
  class Engine < Rails::Engine
    engine_name 'spree_gateway'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer "spree.gateway.payment_methods", :after => "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::BillingIntegration::Skrill::QuickCheckout
      app.config.spree.payment_methods << Spree::Gateway::AuthorizeNet
      app.config.spree.payment_methods << Spree::Gateway::AuthorizeNetCim
      app.config.spree.payment_methods << Spree::Gateway::BalancedGateway
      app.config.spree.payment_methods << Spree::Gateway::Banwire
      app.config.spree.payment_methods << Spree::Gateway::Beanstream
      app.config.spree.payment_methods << Spree::Gateway::BraintreeGateway
      app.config.spree.payment_methods << Spree::Gateway::CardSave
      app.config.spree.payment_methods << Spree::Gateway::CyberSource
      app.config.spree.payment_methods << Spree::Gateway::DataCash
      app.config.spree.payment_methods << Spree::Gateway::Eway
      app.config.spree.payment_methods << Spree::Gateway::Maxipago
      app.config.spree.payment_methods << Spree::Gateway::Migs
      app.config.spree.payment_methods << Spree::Gateway::Moneris
      app.config.spree.payment_methods << Spree::Gateway::PayJunction
      app.config.spree.payment_methods << Spree::Gateway::PayPalGateway
      app.config.spree.payment_methods << Spree::Gateway::PayflowPro
      app.config.spree.payment_methods << Spree::Gateway::Paymill
      app.config.spree.payment_methods << Spree::Gateway::PinGateway
      app.config.spree.payment_methods << Spree::Gateway::SagePay
      app.config.spree.payment_methods << Spree::Gateway::SecurePayAU
      app.config.spree.payment_methods << Spree::Gateway::SpreedlyCoreGateway
      app.config.spree.payment_methods << Spree::Gateway::StripeGateway
      app.config.spree.payment_methods << Spree::Gateway::UsaEpayTransaction
      app.config.spree.payment_methods << Spree::Gateway::Worldpay
    end

    def self.activate
      if SpreeGateway::Engine.frontend_available?
        Rails.application.config.assets.precompile += [
          'lib/assets/javascripts/spree/frontend/spree_gateway.js',
          'lib/assets/javascripts/spree/frontend/spree_gateway.css',
        ]
        Dir.glob(File.join(File.dirname(__FILE__), "../../controllers/frontend/*/*_decorator*.rb")) do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end
    end

    def self.backend_available?
      @@backend_available ||= ::Rails::Engine.subclasses.map(&:instance).map{ |e| e.class.to_s }.include?('Spree::Backend::Engine')
    end

    def self.frontend_available?
      @@frontend_available ||= ::Rails::Engine.subclasses.map(&:instance).map{ |e| e.class.to_s }.include?('Spree::Frontend::Engine')
    end

    if self.backend_available?
      paths["app/views"] << "lib/views/backend"
    end

    if self.frontend_available?
      paths["app/controllers"] << "lib/controllers/frontend"
      paths["app/views"] << "lib/views/frontend"
    end

    config.to_prepare &method(:activate).to_proc
  end
end
