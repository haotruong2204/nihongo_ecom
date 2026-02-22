# frozen_string_literal: true

class SrsCard < ApplicationRecord
  belongs_to :user

  enum :state, { new_card: 0, learning: 1, review: 2, relearning: 3 }

  validates :kanji, presence: true, length: { maximum: 10 }
  validates :kanji, uniqueness: { scope: :user_id }
  validates :ease, presence: true, numericality: { greater_than_or_equal_to: 1.3 }
  validates :interval, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :due_date, presence: true

  scope :due_today, -> { where(due_date: ..Time.current) }
  scope :by_state, ->(state) { where(state: state) }
  scope :young, -> { review.where(interval: ...21) }
  scope :mature, -> { review.where(interval: 21..) }

  def self.ransackable_attributes _auth_object = nil
    %w[kanji state due_date created_at]
  end
end
