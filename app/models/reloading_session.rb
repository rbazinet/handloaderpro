# frozen_string_literal: true

# class to capture all data from a reloading session
class ReloadingSession < ApplicationRecord
  broadcasts_refreshes

  belongs_to :account
  belongs_to :cartridge
  belongs_to :cartridge_type
  belongs_to :reloading_data_source
  belongs_to :bullet
  belongs_to :bullet_weight, optional: true
  belongs_to :powder
  belongs_to :primer
  belongs_to :primer_type

  validates :loaded_at, presence: true
  validates :quantity, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
  validates :cartridge_overall_length, numericality: {greater_than: 0}, allow_nil: true
  validates :powder_weight, numericality: {greater_than: 0}, allow_nil: true
  validates :bullet_weight_other, numericality: {greater_than: 0}, allow_nil: true

  # Either bullet_weight_id or bullet_weight_other must be present
  validate :bullet_weight_presence

  private

  def bullet_weight_presence
    if bullet_weight_id.blank? && bullet_weight_other.blank?
      errors.add(:base, "Bullet weight must be selected or custom weight must be entered")
    end
  end
end
