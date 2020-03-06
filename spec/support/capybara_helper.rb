module CapybaraHelper
  def wait_for(options = {}) 
    default_options = { error: nil, seconds: 5 }.merge(options)

    Selenium::WebDriver::Wait.new(timeout: default_options[:seconds]).until { yield }
  rescue Selenium::WebDriver::Error::TimeOutError
    default_options[:error].nil? ? false : raise(default_options[:error])
  end
end

RSpec.configure do |config|
  config.include CapybaraHelper, type: :feature
end