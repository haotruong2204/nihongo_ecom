# frozen_string_literal: true

class RoadmapDayProgress < ApplicationRecord
  belongs_to :user

  validates :day, presence: true, uniqueness: { scope: :user_id }, numericality: { only_integer: true, in: 1..250 }
  validates :kanji_learned, presence: true
  validates :completed_at, presence: true

  scope :ordered, -> { order(:day) }

  def self.ransackable_attributes _auth_object = nil
    %w[day completed_at created_at]
  end
end
