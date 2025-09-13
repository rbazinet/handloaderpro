# frozen_string_literal: true

# Join model for many-to-many relationship between cartridge types and cartridges
class CartridgeTypeCartridge < ApplicationRecord
  belongs_to :cartridge_type
  belongs_to :cartridge

  validates :cartridge_type_id, uniqueness: {scope: :cartridge_id}
end
