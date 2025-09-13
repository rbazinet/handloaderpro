# frozen_string_literal: true

# Join model for many-to-many relationship between cartridge types and bullet weights
class CartridgeTypeBulletWeight < ApplicationRecord
  belongs_to :cartridge_type
  belongs_to :bullet_weight

  validates :cartridge_type_id, uniqueness: {scope: :bullet_weight_id}
end
