# frozen_string_literal: true

# class for bullet weights
class BulletWeight < ApplicationRecord
  # belongs_to :cartridge  # Removed direct cartridge association
  has_many :cartridge_type_bullet_weights, dependent: :destroy
  has_many :cartridge_types, through: :cartridge_type_bullet_weights

  validates :weight, presence: true, uniqueness: true

  def self.for_select(cartridge_type_id)
    joins(:cartridge_types).where(cartridge_types: {id: cartridge_type_id}).order(:weight).map { |bw| [bw.weight, bw.id] }
  end
end
