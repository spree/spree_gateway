module Spree
  CheckoutController.class_eval do
    before_filter :confirm_skrill, :only => [:update]

    def skrill_return

      unless @order.payments.where(:source_type => 'Spree::SkrillTransaction').present?
        payment_method = PaymentMethod.find(params[:payment_method_id])
        skrill_transaction = SkrillTransaction.new

        payment = @order.payments.create({:amount => @order.total,
                                         :source => skrill_transaction,
                                         :payment_method => payment_method},
                                         :without_protection => true)
        payment.started_processing!
        payment.pend!
      end

      @order.update_attributes({:state => "complete", :completed_at => Time.now}, :without_protection => true)      

      until @order.state == "complete"
        if @order.next!
          @order.update!
          state_callback(:after)
        end
      end

      @order.finalize!

      flash.notice = Spree.t(:order_processed_successfully)
      redirect_to completion_route
    end

    def skrill_cancel
      flash[:error] = Spree.t(:payment_has_been_cancelled)
      redirect_to edit_order_path(@order)
    end

    private
    def confirm_skrill
      return unless (params[:state] == "payment") && params[:order][:payments_attributes]

      payment_method = PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      if payment_method.kind_of?(BillingIntegration::Skrill::QuickCheckout)
        #TODO confirming payment method
        redirect_to edit_order_checkout_url(@order, :state => 'payment'),
                    :notice => Spree.t(:complete_skrill_checkout)
      end
    end
  end
end
