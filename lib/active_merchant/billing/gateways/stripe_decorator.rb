ActiveMerchant::Billing::StripeGateway.class_eval do
  private

  alias_method :original_headers, :headers
  alias_method :original_add_customer_data, :add_customer_data

  def headers(options = {})
    headers = original_headers(options)
    headers['User-Agent'] = headers['X-Stripe-Client-User-Agent']
    headers
  end

  def add_customer_data(post, options)
    original_add_customer_data(post, options)
    post[:payment_user_agent] = "SpreeGateway/#{SpreeGateway.version}"
  end
end
