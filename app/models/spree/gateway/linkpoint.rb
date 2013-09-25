module Spree
  class Gateway::Linkpoint < Gateway
    preference :login, :string
    preference :pem, :text

    def provider_class
      ActiveMerchant::Billing::LinkpointGateway
    end

    [:authorize, :purchase, :capture, :void, :credit].each do |method|
      define_method(method) do |*args|
        options = add_discount_to_subtotal(args.extract_options!)
        provider.public_send(method, *args << options)
      end
    end

    private

    # Linkpoint ignores the discount, but it will return an error if the
    # chargetotal is different from the sum of the subtotal, tax and
    # shipping totals.
    def add_discount_to_subtotal(options)
      subtotal = options.fetch(:subtotal)
      discount = options.fetch(:discount)
      options.merge(subtotal: subtotal + discount, discount: 0)
    end
  end
end
