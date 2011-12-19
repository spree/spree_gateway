SpreeGateway
============

Community supported Spree Payment Method Gateways. 

These can be used with Spree 1.0.x

http://guides.spreecommerce.com/payment_gateways.html

Installation
=======

In your gemfile:

gem 'spree'
gem 'spree_gateway' # make sure to include after spree

bundle install

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test app
    $ bundle exec rspec spec

Copyright (c) 2011 Spree Commerce, released under the New BSD License
