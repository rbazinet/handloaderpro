# frozen_string_literal: true

# Join model for many-to-many relationship between cartridge types and manufacturers
class CartridgeTypeManufacturer < ApplicationRecord
  belongs_to :cartridge_type
  belongs_to :manufacturer

  validates :cartridge_type_id, uniqueness: {scope: :manufacturer_id}
end
