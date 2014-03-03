require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'spree/testing_support/common_rake'

RSpec::Core::RakeTask.new

task :default => [:spec]

desc "Generates a dummy app for testing"
task :test_app do
  ENV['LIB_NAME'] = 'spree_gateway'
  Rake::Task['common:test_app'].invoke
end