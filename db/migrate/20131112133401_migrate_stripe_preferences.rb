class MigrateStripePreferences < ActiveRecord::Migration
  def up
    Spree::Preference.all.where("key LIKE 'spree/gateway/stripe_gateway/login%'").each do |pref|
      pref.key = pref.key.gsub('login', 'secret_key')
      pref.save
    end
  end
end
