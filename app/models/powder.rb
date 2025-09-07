# == Schema Information
#
# Table name: powders
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  manufacturer_id :integer
#
class Powder < ApplicationRecord
  belongs_to :manufacturer
  has_many :cartridge_type_powders, dependent: :destroy
  has_many :cartridge_types, through: :cartridge_type_powders

  accepts_nested_attributes_for :cartridge_type_powders, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validates_associated :manufacturer

  scope :for_cartridge_type, ->(cartridge_type_id) { joins(:cartridge_types).where(cartridge_types: {id: cartridge_type_id}) }

  # Allow updating cartridge type associations via admin interface
  def cartridge_type_ids=(ids)
    # Remove empty strings and convert to integers
    ids = ids.reject(&:blank?).map(&:to_i)
    self.cartridge_types = CartridgeType.where(id: ids)
  end

  # Broadcast changes in realtime with Hotwire
  # after_create_commit -> { broadcast_prepend_later_to :powders, partial: "powders/index", locals: {powder: self} }
  # after_update_commit -> { broadcast_replace_later_to self }
  # after_destroy_commit -> { broadcast_remove_to :powders, target: dom_id(self, :index) }
end
