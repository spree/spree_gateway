SpreeGateway
============

Community supported Spree Payment Method Gateways. 

These can be used with Spree 1.0.x (but see note below for necessary changes)

http://guides.spreecommerce.com/payment_gateways.html

Installation
=======


In your Gemfile:

    gem 'spree'
    gem 'spree_gateway', :git => 'git://github.com/spree/spree_gateway.git', :branch => "1-1-stable" # make sure to include after spree

**Note:** *If you are not using the latest Spree, please consult the Versionfile at the
root of the repository to determine which branch to use.*

Then run from the command line:

    $ bundle install
    $ rails g spree_gateway:install

Finally, make sure to **restart your app**. Navigate to *Configuration > Payment Methods > New Payment Method*  in the admin panel and you should see that a bunch of additional gateways have been added to the list.

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

    $ bundle
    $ bundle exec rake test app
    $ bundle exec rspec spec

Copyright (c) 2011 Spree Commerce, released under the New BSD License
