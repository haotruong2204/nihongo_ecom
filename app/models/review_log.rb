# frozen_string_literal: true

class ReviewLog < ApplicationRecord
  belongs_to :user, counter_cache: true

  enum :rating, { again: 1, hard: 2, good: 3, easy: 4 }

  after_create_commit :increment_total_reviews_ever

  private

  def increment_total_reviews_ever
    user.increment!(:total_reviews_ever)
  end

  validates :kanji, presence: true, length: { maximum: 50 }
  validates :rating, presence: true
  validates :reviewed_at, presence: true

  scope :on_date, ->(date) { where(reviewed_at: date.all_day) }
  scope :for_kanji, ->(kanji) { where(kanji: kanji) }

  def self.ransackable_attributes _auth_object = nil
    %w[kanji rating reviewed_at created_at]
  end
end
