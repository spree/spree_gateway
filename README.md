# Spree Gateway

[![Build Status](https://api.travis-ci.org/spree/spree_gateway.svg?branch=main)](https://travis-ci.org/spree/spree_gateway)
[![Code Climate](https://codeclimate.com/github/spree/spree_gateway.svg)](https://codeclimate.com/github/spree/spree_gateway)

Community supported Spree Payment Method Gateways. It works as a wrapper for
[active_merchant](https://github.com/activemerchant/active_merchant) gateway. 

Supported payment gateways:
* Authorize.net (with CIM support)
* Apple Pay (via Stripe)
* BanWire
* Bambora (previously Beanstream)
* Braintree
* CyberSource
* ePay
* eWay
* maxipago
* MasterCard Payment Gateway Service (formerly MiGS)
* Moneris
* PayJunction
* Payflow
* Paymill
* Pin Payments
* QuickPay
* sage Pay
* SecurePay
* Spreedly
* Stripe (with Stripe Elements)
* USAePay
* Worldpay (previously Cardsave)

For`PayPal` support head over to [braintree_vzero](https://github.com/spree-contrib/spree_braintree_vzero) extension.

## Installation

1. Add this extension to your Gemfile with this line:

    ```ruby
    gem 'spree_gateway', '~> 3.7'
    ```

2. Install the gem using Bundler:
    ```ruby
    bundle install
    ```

3. Copy & run migrations
    ```ruby
    bundle exec rails g spree_gateway:install
    ```

Finally, make sure to **restart your app**. Navigate to *Configuration > Payment Methods > New Payment Method* in the admin panel and you should see that a bunch of additional gateways have been added to the list.

## Contributing

In the spirit of [free software][1], **everyone** is encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using prerelease versions
* by reporting [bugs][2]
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (*no patch is too small*: fix typos, add comments, clean up inconsistent whitespace)
* by refactoring code
* by resolving [issues][2]
* by reviewing patches

Starting point:

* Fork the repo
* Clone your repo
* (You will need to `brew install mysql postgres` if you don't already have them installed)
* Run `bundle`
* (You may need to `bundle update` if bundler gets stuck)
* Run `bundle exec rake test_app` to create the test application in `spec/test_app`
* Make your changes
* Ensure specs pass by running `bundle exec rspec spec`
* (You will need to `brew install phantomjs` if you don't already have it installed)
* Submit your pull request


License
----------------------

Spree is released under the [New BSD License][3].

About Spark Solutions
----------------------
[![Spark Solutions](http://sparksolutions.co/wp-content/uploads/2015/01/logo-ss-tr-221x100.png)][spark]

Spree Gateway is maintained by [Spark Solutions Sp. z o.o.][spark].

We are passionate about open source software.
We are [available for hire][spark].

[spark]:http://sparksolutions.co?utm_source=github

[1]: http://www.fsf.org/licensing/essays/free-sw.html
[2]: https://github.com/spree/spree_gateway/issues
[3]: https://github.com/spree/spree_gateway/blob/main/LICENSE.md
[4]: https://github.com/spree
[5]: https://github.com/spree/spree_gateway/graphs/contributors
