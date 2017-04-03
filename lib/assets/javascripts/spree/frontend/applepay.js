var ApplePay = function ($applePay) {
  this.order_price = $applePay.data('price');
  this.publishable_key = $applePay.data('publishable-key');
  this.payment_method_id = $applePay.data('payment-method-id');
  this.payment_method_name = $applePay.data('payment-method-name');
  this.currencyCode = $applePay.data('currency');
  this.countryCode = $applePay.data('country');

  this.mapCC = { 'MasterCard': 'mastercard',
                 'Visa': 'visa',
                 'American Express': 'amex',
                 'Discover': 'discover',
                 'Diners Club': 'dinersclub',
                 'JCB': 'jcb'
              };
};

ApplePay.prototype.init = function () {
  this.checkAvailability();
  this.bindEvents();
};

ApplePay.prototype.checkAvailability =  function () {
  var _this = this;
  Stripe.setPublishableKey(this.publishable_key);
  Stripe.applePay.checkAvailability(function(){
    _this.toggleButton();
  });
};

ApplePay.prototype.bindEvents = function () {
  var _this = this;
  $('#apple-pay-button').on('click', function(){
    _this.startPaymentRequest();
  });
};

ApplePay.prototype.toggleButton = function (available) {
  if (available) {
    $('#apple-pay-button').show();
  } else {
    var $label = $('#payment-method-fields').find($("label:contains(" + this.payment_method_name + ")"));
    $label.hide();
    $label.find($("input[type=radio]")).attr('disabled', true);
  }
};

ApplePay.prototype.handleStripeResponse = function (result, completion) {
  Spree.applePaymentMethod.find('#card_number, #card_expiry, #card_code, .ccType').prop("disabled", true);
  var token = result['token'];
  var paymentMethodId = Spree.applePaymentMethod.prop('id').split("_")[2];
  Spree.applePaymentMethod.append("<input type='hidden' class='ccType' name='payment_source[" + paymentMethodId + "][cc_type]' value='" + this.mapCC[token.card.brand] + "'/>");
  Spree.applePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId + "][gateway_payment_profile_id]' value='" + token.id + "'/>");
  Spree.applePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId + "][last_digits]' value='" + token.card.last4 + "'/>");
  Spree.applePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId + "][month]' value='" + token.card.exp_month + "'/>");
  Spree.applePaymentMethod.append("<input type='hidden' class='stripeToken' name='payment_source[" + paymentMethodId + "][year]' value='" + token.card.exp_year + "'/>");
  return Spree.applePaymentMethod.parents("form").get(0).submit();
};

ApplePay.prototype.startPaymentRequest = function () {
  this.paymentRequest = {
    countryCode: this.countryCode,
    currencyCode: this.currencyCode,
    total: {
      label: 'Stripe.com',
      amount: this.order_price
    }
  };
  this.startSession();
};

ApplePay.prototype.startSession = function () {
  var _this = this;
  Spree.applePaymentMethod = $('#payment_method_' + this.payment_method_id);
  var session = Stripe.applePay.buildSession(this.paymentRequest,
    function(result, completion) {
      _this.handleStripeResponse(result, completion);
  }, function(error) {
    console.log(error.message);
  });
  session.begin();
};
