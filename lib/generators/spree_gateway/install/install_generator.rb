module SpreeGateway
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_gateway'
      end

      def run_migrations
         if running_migrations?
           run 'bundle exec rake db:migrate'
         else
           puts "Skiping rake db:migrate, don't forget to run it!"
         end
      end

      private

      def running_migrations?
         options.auto_run_migrations? || begin
           response = ask 'Would you like to run the migrations now? [Y/n]'
           ['', 'y'].include? response.downcase
         end
      end
    end
  end
end
