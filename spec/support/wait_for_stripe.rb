module WaitForStripe
  def wait_for_stripe
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('window.activeStripeRequests').zero?
    end
  end

  def setup_stripe_watcher
    page.evaluate_script <<-JS
      window.activeStripeRequests = 0;
      $('#checkout_form_payment [data-hook=buttons]').on('click', function() {
        window.activeStripeRequests = window.activeStripeRequests + 1;
      });
      stripeResponseHandler = (function() {
        var _f = stripeResponseHandler;
        return function() {
          window.activeStripeRequests = window.activeStripeRequests - 1;
          _f.apply(this, arguments);
        }
      })();
    JS
  end
end

RSpec.configure do |config|
  config.include WaitForStripe, type: :feature
end
