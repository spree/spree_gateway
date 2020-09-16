script = '
<div id="errorBox" class="errorExplanation alert alert-danger" style="display:none"></div>
<div id="successBox" class="alert alert-success" style="display:none"></div>

<% intent_secrets = @order.payments.valid.map do |payment|
  next unless payment.intent_client_key
  {
    intent_key: payment.intent_client_key,
    pk_key: payment.payment_method.preferred_publishable_key
  }
end.last %>

<% if intent_secrets %>
  <script type="text/javascript" src="https://js.stripe.com/v3/"></script>
  <script>

    function confirmCardPaymentResponseHandler(response) {
      $.post("/api/v1/stripe/intents/handle_response", { response: response, order_id: "<%= @order.id %>" })
        .done(function (result) {
          $("#successBox").html(result.message);
          $("#successBox").show();
        }).fail(function(result) {
          $("#errorBox").html(result.responseJSON.errors);
          $("#errorBox").show();
        }
      );
    };

    console.log("secret", "<%= intent_secrets[:intent_key] %>");
    console.log("key", "<%= intent_secrets[:pk_key] %>");

    var stripeElements = Stripe("<%= intent_secrets[:pk_key] %>");
    stripeElements.confirmCardPayment("<%= intent_secrets[:intent_key] %>").then(function(result) {
      confirmCardPaymentResponseHandler(result)
    });
  </script>
<% end %>
'
Deface::Override.new(virtual_path: "spree/orders/show",
                     name: "sca-script",
                     insert_after: "div.order-show",
                     text: script)
