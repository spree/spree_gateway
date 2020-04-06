module Spree
  class Check < Spree::Base

    attr_accessor :imported

    belongs_to :payment_method
    belongs_to :user, class_name: Spree.user_class.to_s, foreign_key: 'user_id',
               optional: true
    has_many :payments, as: :source

    scope :with_payment_profile, -> { where.not(gateway_customer_profile_id: nil) }

    validates :account_holder_name, presence: true
    validates :account_holder_type, presence: true, inclusion: { in: %w[Individual Company] }
    validates :account_number, presence: true, numericality: { only_integer: true }
    validates :routing_number, presence: true, numericality: { only_integer: true }

    def has_payment_profile?
      gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
    end

    def actions
      %w[capture void credit]
    end

    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.failed? && !payment.void?
    end

    # Indicates whether its possible to credit the payment.  Note that most gateways require that the
    # payment be settled first which generally happens within 12-24 hours of the transaction.
    def can_credit?(payment)
      payment.completed? && payment.credit_allowed > 0
    end
  end
end
