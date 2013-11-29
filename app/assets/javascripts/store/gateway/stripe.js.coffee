# Inspired by https://stripe.com/docs/stripe.js

# Map cc types from stripe to spree
mapCC = (ccType) ->
  if (ccType == 'MasterCard') 
    'mastercard'
  else if (ccType == 'Visa') 
    'visa'
  else if (ccType == 'American Express')
    'amex'
  else if (ccType == 'Discover')
    'discover'
  else if (ccType == 'Diners Club')
    'dinersclub'
  else if (ccType == 'JCB')
    'jcb'


$(document).ready ->
  # For errors that happen later.
  Spree.stripePaymentMethod.prepend("<div id='stripeError' class='errorExplanation' style='display:none'></div>")

  $('.continue').click ->
    $('#stripeError').hide()
    if Spree.stripePaymentMethod.is(':visible')
      expiration = $('.cardExpiry:visible').payment('cardExpiryVal')
      params = $.extend(
        {
          number: $('.cardNumber:visible').val(),
          cvc: $('.cardCode:visible').val(),
          exp_month: expiration.month || 0,
          exp_year: expiration.year || 0,
        },
        Spree.stripeAdditionalInfo
      )

      Stripe.card.createToken(params, stripeResponseHandler);
      return false

stripeResponseHandler = (status, response) ->
  if response.error
    $('#stripeError').html(response.error.message)
    $('#stripeError').show()
  else
    Spree.stripePaymentMethod.find('#card_number, #card_expiry, #card_code').prop("disabled" , true)
    Spree.stripePaymentMethod.find(".ccType").prop("disabled", false)
    Spree.stripePaymentMethod.find(".ccType").val(mapCC(response.card.type))

    # token contains id, last4, and card type
    token = response['id'];
    # insert the token into the form so it gets submitted to the server
    paymentMethodId = Spree.stripePaymentMethod.prop('id').split("_")[2]
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId  + "][gateway_payment_profile_id]' value='" + token + "'/>");
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId  + "][last_digits]' value='" + response.card.last4 + "'/>");
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId  + "][month]' value='" + response.card.exp_month + "'/>");
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId  + "][year]' value='" + response.card.exp_year + "'/>");
    # Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId  + "][cc_type]' value='" + mapCC(response.card.type) + "'/>");
    Spree.stripePaymentMethod.parents("form").get(0).submit();
