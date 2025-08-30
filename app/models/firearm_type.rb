# frozen_string_literal: true

# == Schema Information
#
# Table name: firearm_types
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class FirearmType < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
