module Spree
  class Gateway::Worldpay < Gateway
    preference :login, :string
    preference :password, :string
    preference :currency, :string, :default => 'GBP'
    preference :installation_id, :string

    preference :american_express_login, :string
    preference :discover_login, :string
    preference :jcb_login, :string
    preference :mastercard_login, :string
    preference :maestro_login, :string
    preference :visa_login, :string

    def provider_class
      ActiveMerchant::Billing::WorldpayGateway
    end

    def purchase(money, credit_card, options = {})
      provider = credit_card_provider(credit_card, options)
      provider.purchase(money, credit_card, options)
    end

    def authorize(money, credit_card, options = {})
      provider = credit_card_provider(credit_card, options)
      provider.authorize(money, credit_card, options)
    end

    def capture(money, authorization, options = {})
      provider = credit_card_provider(auth_credit_card(authorization), options)
      provider.capture(money, authorization, options)
    end

    def refund(money, authorization, options = {})
      provider = credit_card_provider(auth_credit_card(authorization), options)
      provider.refund(money, authorization, options)
    end

    def credit(money, authorization, options = {})
      refund(money, authorization, options)
    end

    def void(authorization, options = {})
      provider = credit_card_provider(auth_credit_card(authorization), options)
      provider.void(authorization, options)
    end

    private

    def options_for_card(credit_card, options)
      options[:login] = login_for_card(credit_card)
      options = options().merge( options )
    end

    def auth_credit_card(authorization)
      Spree::Payment.find_by_response_code(authorization).source
    end

    def credit_card_provider(credit_card, options = {})
      gateway_options = options_for_card(credit_card, options)
      gateway_options.delete :login if gateway_options.has_key?(:login) and gateway_options[:login].nil?
      gateway_options[:currency] = self.preferred_currency
      gateway_options[:inst_id] = self.preferred_installation_id
      ActiveMerchant::Billing::Base.gateway_mode = gateway_options[:server].to_sym
      @provider = provider_class.new(gateway_options)
    end

    def login_for_card(card)
      case card.brand
        when 'american_express'
          choose_login preferred_american_express_login
        when 'discover'
          choose_login preferred_discover_login
        when 'jcb'
          choose_login preferred_jcb_login
        when 'maestro'
          choose_login preferred_maestro_login
        when 'master'
          choose_login preferred_mastercard_login
        when 'visa'
          choose_login preferred_visa_login
        else
          preferred_login
      end
    end

    def choose_login(login)
      return login ? login : preferred_login
    end
  end
end
