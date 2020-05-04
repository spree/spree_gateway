script = '
<% intent_secrets = @order.payments.valid.map do |payment|
  next unless payment.intent_client_key
  {
    intent_key: payment.intent_client_key,
    pk_key: payment.payment_method.preferred_publishable_key
  }
end.last %>

<% if intent_secrets && order_just_completed?(@order) %>
  <script type="text/javascript" src="https://js.stripe.com/v3/"></script>
  <script>

    function confirmCardPaymentResponseHandler(response) {
      $.post("/stripe/intents/handle", { response: response, order: "<%= @order.number %>", authenticity_token: "<%= form_authenticity_token %>" })
    };

    var stripeElements = Stripe("<%= intent_secrets[:pk_key] %>");
    stripeElements.confirmCardPayment("<%=intent_secrets[:intent_key]%>").then(function(result) {
      confirmCardPaymentResponseHandler(result)
    });
  </script>
<% end %>
'
Deface::Override.new(:virtual_path => "spree/orders/show",
                     :name => "sca-script",
                     :insert_after => "div.order-show",
                     :text => script)
