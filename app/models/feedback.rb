# frozen_string_literal: true

class Feedback < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :parent, class_name: "Feedback", optional: true
  has_many :replies, class_name: "Feedback", foreign_key: :parent_id, dependent: :destroy
  has_many :displayed_replies, -> { where(display: true) }, class_name: "Feedback", foreign_key: :parent_id

  enum :status, { pending: 0, reviewed: 1, done: 2, rejected: 3 }

  validates :text, presence: true

  scope :displayed, -> { where(display: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :roots, -> { where(parent_id: nil) }

  after_create_commit { BroadcastFeedbackJob.perform_later(id, "created") }
  after_update_commit { BroadcastFeedbackJob.perform_later(id, "updated") }
  after_destroy_commit { BroadcastFeedbackJob.perform_later(id, "destroyed") }

  def self.ransackable_attributes _auth_object = nil
    %w[status email display created_at context_type context_id parent_id]
  end
end
