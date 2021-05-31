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

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/spree/spree_gateway/issues",
    "changelog_uri"     => "https://github.com/spree/spree_gateway/releases/tag/v#{s.version}",
    "documentation_uri" => "https://guides.spreecommerce.org/",
    "source_code_uri"   => "https://github.com/spree/spree_gateway/tree/v#{s.version}",
  }

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 3.7.0'
  s.add_dependency 'spree_extension'

  s.add_development_dependency 'braintree', '~> 3.0.0'
  s.add_development_dependency 'rspec-activemodel-mocks'
  s.add_development_dependency 'spree_dev_tools'
end
