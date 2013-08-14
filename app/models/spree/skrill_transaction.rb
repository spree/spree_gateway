module Spree
  class SkrillTransaction < ActiveRecord::Base
    has_many :payments, :as => :source

    def actions
      []
    end

    def self.create_from_postback(params)
       SkrillTransaction.create(:email => params[:pay_from_email],
                               :amount => params[:mb_amount],
                               :currency => params[:mb_currency],
                               :transaction_id => params[:mb_transaction_id],
                               :customer_id => params[:customer_id],
                               :payment_type => params[:payment_type])
    end

  end
end
