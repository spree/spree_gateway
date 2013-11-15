# Inspired by https://stripe.com/docs/stripe.js

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
          exp_month: expiration.month,
          exp_year: expiration.year,
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
    # token contains id, last4, and card type
    token = response['id'];
    # insert the token into the form so it gets submitted to the server
    paymentMethodId = Spree.stripePaymentMethod.prop('id').split("_")[2]
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId  + "][gateway_payment_profile_id]' value='" + token + "'/>");
    # insert additional card info to save to the payment source
    expiration = $('.cardExpiry:visible').payment('cardExpiryVal')
    Spree.stripePaymentMethod.append("<input type='hidden' name='payment_source[" + paymentMethodId + "][month]' value='" + expiration.month + "'/>");
    Spree.stripePaymentMethod.append("<input type='hidden' name='payment_source[" + paymentMethodId + "][year]' value='" + expiration.year + "'/>");
    Spree.stripePaymentMethod.parents("form").get(0).submit();
