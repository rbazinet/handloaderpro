# frozen_string_literal: true

# Join model for many-to-many relationship between cartridge types and powders
class CartridgeTypePowder < ApplicationRecord
  belongs_to :cartridge_type
  belongs_to :powder

  validates :cartridge_type_id, uniqueness: {scope: :powder_id}
end
