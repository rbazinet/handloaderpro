class Account < ApplicationRecord
  has_prefix_id :acct

  include Billing
  include Domains
  include Reloading
  include Transfer
  include Types
end
