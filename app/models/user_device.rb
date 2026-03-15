# frozen_string_literal: true

class UserDevice < ApplicationRecord
  belongs_to :user

  validates :device_id, presence: true, uniqueness: { scope: :user_id }
  validates :device_name, presence: true
  validates :last_seen_at, presence: true

  scope :recent, -> { order(last_seen_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[device_id device_name last_seen_at created_at]
  end
end
