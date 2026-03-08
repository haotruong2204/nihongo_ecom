# frozen_string_literal: true

class TangoLessonProgress < ApplicationRecord
  belongs_to :user, counter_cache: true

  validates :book_id, presence: true
  validates :lesson_id, presence: true
  validates :lesson_id, uniqueness: { scope: %i[user_id book_id] }
  validates :known_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :completed, -> { where(completed: true) }
  scope :for_book, ->(book_id) { where(book_id: book_id) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[book_id lesson_id completed last_studied_at created_at]
  end
end
