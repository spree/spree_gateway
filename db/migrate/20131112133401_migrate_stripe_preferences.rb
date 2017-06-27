class MigrateStripePreferences < SpreeExtension::Migration[4.2]
  def up
    Spree::Preference.where("#{ActiveRecord::Base.connection.quote_column_name("key")} LIKE 'spree/gateway/stripe_gateway/login%'").each do |pref|
      pref.key = pref.key.gsub('login', 'secret_key')
      pref.save
    end
  end
end
