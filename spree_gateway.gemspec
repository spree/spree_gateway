# coding: utf-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gateway'
  s.version     = '3.2.0'
  s.summary     = 'Additional Payment Gateways for Spree Commerce'
  s.description = s.summary

  s.author       = 'Spree Commerce'
  s.email        = 'gems@spreecommerce.com'
  s.homepage     = 'http://www.spreecommerce.com'
  s.license      = %q{BSD-3}

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 3.1.0', '< 4.0'
  s.add_dependency 'spree_core', spree_version

  s.add_development_dependency 'braintree'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'capybara-screenshot'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'bootstrap-sass', '>= 3.3.5.1'
  s.add_development_dependency 'sass-rails', '>= 3.2'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'appraisal'
end
