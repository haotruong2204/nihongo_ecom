# frozen_string_literal: true

class JlptTestResult < ApplicationRecord
  belongs_to :user

  validates :level, presence: true, inclusion: { in: %w[N5 N4 N3 N2 N1] }
  validates :correct_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :incorrect_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_questions, presence: true, numericality: { greater_than: 0 }
  validates :time_used, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_limit, presence: true, numericality: { greater_than: 0 }
  validates :taken_at, presence: true
  validates :sections, presence: true

  scope :for_level, ->(level) { where(level: level) }
  scope :recent, -> { order(taken_at: :desc) }
  scope :passed, -> { where(passed: true) }
end
