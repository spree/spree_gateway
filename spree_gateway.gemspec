# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'spree_gateway/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gateway'
  s.version     = SpreeGateway.version
  s.summary     = 'Additional Payment Gateways for Spree Commerce'
  s.description = s.summary

  s.author       = 'Spree Commerce'
  s.email        = 'gems@spreecommerce.com'
  s.homepage     = 'https://spreecommerce.org'
  s.license      = 'BSD-3-Clause'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  spree_version = '>= 3.1.0', '< 5.0'
  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'spree_extension'

  s.add_development_dependency 'braintree'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'spree_dev_tools'
end
