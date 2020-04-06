module Spree
  module PermittedAttributes
    @@source_attributes += %i[account_number routing_number account_holder_type account_holder_name status]
  end
end
