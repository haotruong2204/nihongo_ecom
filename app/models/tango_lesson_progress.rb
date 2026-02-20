# frozen_string_literal: true

class TangoLessonProgress < ApplicationRecord
  belongs_to :user

  validates :book_id, presence: true, length: { maximum: 50 }
  validates :lesson_id, presence: true, length: { maximum: 100 }
  validates :lesson_id, uniqueness: { scope: %i[user_id book_id] }
  validates :known_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :for_book, ->(book_id) { where(book_id: book_id) }
  scope :completed, -> { where(completed: true) }
end
