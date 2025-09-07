# == Schema Information
#
# Table name: manufacturers
#
#  id                   :bigint           not null, primary key
#  name                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  manufacturer_type_id :integer
#
class Manufacturer < ApplicationRecord
  belongs_to :manufacturer_type
  has_many :bullets, dependent: :destroy
  has_many :powders, dependent: :destroy
  has_many :primers, dependent: :destroy

  # Broadcast changes in realtime with Hotwire
  # after_create_commit -> { broadcast_prepend_later_to :manufacturers, partial: "manufacturers/index", locals: {manufacturer: self} }
  # after_update_commit -> { broadcast_replace_later_to self }
  # after_destroy_commit -> { broadcast_remove_to :manufacturers, target: dom_id(self, :index) }

  validates :name, presence: true, uniqueness: true
  validates_associated :manufacturer_type
end
