# Spree Gateway

[![Build Status](https://api.travis-ci.org/spree/spree_gateway.png?branch=master)](https://travis-ci.org/spree/spree_gateway)
[![Code Climate](https://codeclimate.com/github/spree/spree_gateway.png)](https://codeclimate.com/github/spree/spree_gateway)

Community supported Spree Payment Method Gateways. It works as a wrapper for
active_merchant gateway. Note that for some gateways you might still need to
add another gem to your Gemfile to make it work. For example active_merchant
require `braintree` but it doesn't include that gem on its gemspec. So you
need to manually add it to your rails app Gemfile.

These can be used with Spree >= 1.0.x (but see note below for necessary changes)

http://guides.spreecommerce.com/developer/payments.html

## Installation

In your Gemfile:

**Spree edge**

```ruby
gem 'spree'
gem 'spree_gateway', github: 'spree/spree_gateway', branch: 'master'
```

**Spree 1.3**

```ruby
gem 'spree', '~> 1.3'
gem 'spree_gateway', github: 'spree/spree_gateway', branch: '1-3-stable'
```

Then run from the command line:

    $ bundle install
    $ rails g spree_gateway:install

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


Copyright (c) 2014 [Spree Commerce][4] and other [contributors][5], released under the [New BSD License][3]

[1]: http://www.fsf.org/licensing/essays/free-sw.html
[2]: https://github.com/spree/spree_gateway/issues
[3]: https://github.com/spree/spree_gateway/blob/master/LICENSE.md
[4]: https://github.com/spree
[5]: https://github.com/spree/spree_gateway/graphs/contributors
