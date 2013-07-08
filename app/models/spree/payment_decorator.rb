Spree::Payment.class_eval do 
  attr_accessible :source, :payment_method
end 