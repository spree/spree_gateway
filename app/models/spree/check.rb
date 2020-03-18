module Spree
  class Check < Spree::Base

    attr_accessor :imported

    belongs_to :payment_method
    belongs_to :user, class_name: Spree.user_class.to_s, foreign_key: 'user_id',
               optional: true
    has_many :payments, as: :source

    scope :with_payment_profile, -> { where.not(gateway_customer_profile_id: nil) }

    def has_payment_profile?
      gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
    end
  end
end
