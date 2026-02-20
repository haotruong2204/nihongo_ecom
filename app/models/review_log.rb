# frozen_string_literal: true

class ReviewLog < ApplicationRecord
  belongs_to :user

  enum :rating, { again: 1, hard: 2, good: 3, easy: 4 }

  validates :kanji, presence: true, length: { maximum: 10 }
  validates :rating, presence: true
  validates :reviewed_at, presence: true

  scope :on_date, ->(date) { where(reviewed_at: date.all_day) }
  scope :for_kanji, ->(kanji) { where(kanji: kanji) }
end
