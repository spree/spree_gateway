# coding: utf-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gateway'
  s.version     = '2.1.0.beta'
  s.summary     = 'Additional Payment Gateways for Spree Commerce'
  s.description = s.summary
  s.required_ruby_version = '>= 1.9.3'

  s.author       = 'Spree Commerce'
  s.email        = 'ryan@spreecommerce.com'
  s.homepage     = 'http://www.spreecommerce.org'
  s.license      = %q{BSD-3}

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.2.0'
  s.add_dependency 'savon', '~> 1.2'

  s.add_dependency 'braintree'

  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'rspec-rails', '~> 2.14'
  s.add_development_dependency 'capybara', '2.2.1'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'coffee-rails', '~> 4.0.0'
  s.add_development_dependency 'sass-rails', '~> 4.0.0'
  s.add_development_dependency 'poltergeist', '1.5.0'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'database_cleaner', '1.2.0'
  s.add_development_dependency 'simplecov', '~> 0.7.1'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pry'
end
