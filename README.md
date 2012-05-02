SpreeGateway
============

Community supported Spree Payment Method Gateways. 

These can be used with Spree 1.0.x (but see note below for necessary changes)

http://guides.spreecommerce.com/payment_gateways.html

Installation
=======

In your Gemfile:

    gem 'spree'
	gem 'spree_gateway', :git => "https://github.com/spree/spree_gateway.git" # make sure to include after spree

Then run from the command line:

	bundle install
	rails g spree_gateway:install

Finally, make sure to **restart your app**. Navigate to *configuration > payment methods > new payment method*  in the admin panel and you should see that a bunch of additional gateways have been added to the list.

##### Note
If you are using Spree 1.0.x,  you will need to load `spree_gateway` in your Gemfile as below, or override the payment_method model and add `attr_accessible :name, :description, :environment, :display_on, :active, :type`. If you do not make one of these modifications, **it will not work** when adding new payment methods.

     gem 'spree_gateway', :git => 'git://github.com/spree/spree_gateway.git', :ref => 'e0aa8bfbb7c26786b276d1a3eaa9820c1aa08c79'

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test app
    $ bundle exec rspec spec

Copyright (c) 2011 Spree Commerce, released under the New BSD License
