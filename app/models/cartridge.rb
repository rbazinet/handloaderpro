# frozen_string_literal: true

# class to keep all data for a cartridge
class Cartridge < ApplicationRecord
  # has_many :bullet_weights, dependent: :destroy  # Removed direct association
  has_many :cartridge_type_cartridges, dependent: :destroy
  has_many :cartridge_types, through: :cartridge_type_cartridges

  validates :name, presence: true, uniqueness: true

  def self.for_select(cartridge_type_id)
    joins(:cartridge_types).where(cartridge_types: {id: cartridge_type_id}).order(:name).map { |c| [c.name, c.id] }
  end
end
