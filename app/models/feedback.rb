# frozen_string_literal: true

class Feedback < ApplicationRecord
  belongs_to :user, optional: true

  enum :status, { pending: 0, reviewed: 1, done: 2, rejected: 3 }

  validates :text, presence: true

  scope :displayed, -> { where(display: true) }
  scope :recent, -> { order(created_at: :desc) }
end
