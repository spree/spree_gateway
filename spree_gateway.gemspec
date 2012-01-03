# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gateway'
  s.version     = '1.0.0'
  s.summary     = 'Spree Gateways'
  s.description = 'Additional Payment Gateways for Spree'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Spree Commerce'
  s.homepage          = 'http://www.spreecommerce.org'

  s.require_path = 'lib'
  s.requirements << 'none'
  s.add_dependency 'samurai'
  s.add_dependency 'spree_core', '>= 1.0.beta'
  s.add_development_dependency 'rspec-rails'
end

