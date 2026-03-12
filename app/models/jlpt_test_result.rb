# frozen_string_literal: true

class JlptTestResult < ApplicationRecord
  belongs_to :user

  validates :test_id, presence: true
  validates :level, presence: true, inclusion: { in: %w[N5 N4 N3 N2 N1] }
  validates :section, inclusion: { in: %w[vocab grammar-reading listening] }, allow_nil: true
  validates :correct_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :incorrect_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_questions, presence: true, numericality: { greater_than: 0 }
  validates :time_used, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_limit, presence: true, numericality: { greater_than: 0 }
  validates :taken_at, presence: true
  validates :sections, presence: true

  scope :for_level, ->(level) { where(level: level) }
  scope :for_test, ->(test_id) { where(test_id: test_id) }
  scope :recent, -> { order(taken_at: :desc) }
  scope :passed, -> { where(passed: true) }
end
