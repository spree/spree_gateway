# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_gateway'
  s.version     = '2.1.0.beta'
  s.summary     = 'Spree Gateways'
  s.description = 'Additional Payment Gateways for Spree'
  s.required_ruby_version = '>= 1.8.7'

  s.author            = 'Spree Commerce'
  s.homepage          = 'http://www.spreecommerce.org'

  s.require_path = 'lib'
  s.requirements << 'none'
  s.add_dependency 'spree_core'
  s.add_dependency 'savon', '~> 1.2'
  s.add_development_dependency 'factory_girl_rails', '~> 4.2.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3'
end
