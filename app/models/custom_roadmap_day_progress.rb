# frozen_string_literal: true

class CustomRoadmapDayProgress < ApplicationRecord
  belongs_to :user
  belongs_to :custom_roadmap

  validates :day, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :day, uniqueness: { scope: [:user_id, :custom_roadmap_id] }
  validates :kanji_learned, presence: true
  validates :completed_at, presence: true

  scope :ordered, -> { order(:day) }

  def self.ransackable_attributes _auth_object = nil
    %w[day completed_at created_at]
  end
end
