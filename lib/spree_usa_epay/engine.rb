module SpreeUsaEpay
  class Engine < Rails::Engine
    engine_name 'spree_usa_epay'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

  end
end
