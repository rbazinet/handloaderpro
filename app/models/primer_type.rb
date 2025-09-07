# frozen_string_literal: true

# == Schema Information
#
# Table name: primer_types
#
#  id                :bigint           not null, primary key
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  cartridge_type_id :bigint           not null
#
class PrimerType < ApplicationRecord
  belongs_to :cartridge_type

  validates :name, presence: true, uniqueness: {scope: :cartridge_type_id}

  # Scopes for filtering by cartridge type
  scope :rifle, -> { joins(:cartridge_type).where(cartridge_types: {name: "Rifle"}) }
  scope :pistol, -> { joins(:cartridge_type).where(cartridge_types: {name: "Pistol"}) }
  scope :shotgun, -> { joins(:cartridge_type).where(cartridge_types: {name: "Shotgun"}) }

  # Method for displaying cartridge type name in admin
  def cartridge_type_name
    cartridge_type&.name
  end

  # Broadcast changes in realtime with Hotwire
  # after_create_commit -> { broadcast_prepend_later_to :primer_types, partial: "primer_types/index", locals: {primer_type: self} }
  # after_update_commit -> { broadcast_replace_later_to self }
  # after_destroy_commit -> { broadcast_remove_to :primer_types, target: dom_id(self, :index) }
end
