module Spree
  class SkrillStatusController < ApplicationController
    def update
      @order = Order.find_by_number!(params[:order_id])
      payment_method = PaymentMethod.find(params[:payment_method_id])
      skrill_transaction = SkrillTransaction.create_from_postback params

      payment = @order.payments.where(:state => "pending",
                                      :payment_method_id => payment_method).first

      if payment
        payment.source = skrill_transaction
        payment.save
      else
        payment = @order.payments.create(:amount => @order.total,
                                         :source => skrill_transaction,
                                         :payment_method => payment_method)
      end

      payment.started_processing!

       unless payment.completed?
        case params[:status]
          when "0"
            payment.pend #may already be pending
          when "2" #processed / captured
            payment.complete!
          when "-1", "-2"
            payment.failure!
          else
            raise "Unexpected payment status"
        end
      end

      render :text => ""
    end

  end
end
