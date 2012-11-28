module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class Skrill < Gateway

      def service_url
        "https://www.moneybookers.com/app/payment.pl"
      end

      def payment_url(opts)
        post = PostData.new
        post.merge! opts

        "#{service_url}?#{post.to_s}"
      end

    end
  end
end
