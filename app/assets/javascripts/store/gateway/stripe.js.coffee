# Inspired by https://stripe.com/docs/stripe.js

$(document).ready ->
  # For errors that happen later.
  Spree.stripePaymentMethod.prepend("<div id='stripeError' class='errorExplanation' style='display:none'></div>")

  $('.continue').click ->
    $('#stripeError').hide()
    if Spree.stripePaymentMethod.is(':visible')
      expiry_parts = $('.cardExpiry:visible').val()
      if expiry_parts.length > 4
        expiry_parts = expiry_parts.split("/")
        expiry_month = expiry_parts[0].replace(/\ /g, '')
        expiry_year = expiry_parts[1].replace(/\ /g, '')
      else
        expiry_month = ""
        expiry_year = ""
      params = $.extend(
        {
          number: $('.cardNumber:visible').val(),
          cvc: $('.cardCode:visible').val(),
          exp_month: expiry_month,
          exp_year: expiry_year,
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
    Spree.stripePaymentMethod.find("input").prop("disabled" , true);
    Spree.stripePaymentMethod.find(".ccType").prop("disabled", false)
    # token contains id, last4, and card type
    token = response['id'];
    # insert the token into the form so it gets submitted to the server
    payment_method_id = Spree.stripePaymentMethod.prop('id').split("_")[2]
    Spree.stripePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + payment_method_id + "][gateway_payment_profile_id]' value='" + token + "'/>");
    Spree.stripePaymentMethod.parents("form").get(0).submit();

