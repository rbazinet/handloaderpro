module Account::Reloading
  extend ActiveSupport::Concern

  included do
    has_many :reloading_sessions, dependent: :destroy
  end
end
