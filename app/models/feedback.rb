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

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_destroyed

  def self.ransackable_attributes _auth_object = nil
    %w[status email display created_at context_type context_id parent_id]
  end

  private

  def root_feedback
    parent || self
  end

  def from_admin?
    user_id.nil? && email == "admin"
  end

  def serialize_feedback(feedback)
    FeedbackSerializer.new(feedback, include: [:replies]).serializable_hash[:data]
  end

  def broadcast_created
    root = root_feedback
    if from_admin?
      broadcast_to_participants(:new_reply)
    else
      ActionCable.server.broadcast("admin_feedbacks", {
        type: "new_feedback",
        feedback: serialize_feedback(root)
      })
    end
  end

  def broadcast_updated
    root = root_feedback
    payload = { type: "feedback_updated", feedback: serialize_feedback(root) }

    ActionCable.server.broadcast("admin_feedbacks", payload)

    user_id = root.user_id
    ActionCable.server.broadcast("user_feedbacks_#{user_id}", payload) if user_id
  end

  def broadcast_destroyed
    root = root_feedback
    payload = { type: "feedback_deleted", feedback_id: id, parent_id: parent_id }

    ActionCable.server.broadcast("admin_feedbacks", payload)

    user_id = root.user_id
    ActionCable.server.broadcast("user_feedbacks_#{user_id}", payload) if user_id
  end

  def broadcast_to_participants(type)
    root = root_feedback
    payload = { type: type, feedback: serialize_feedback(root) }

    participant_user_ids = root.replies.where.not(user_id: nil).distinct.pluck(:user_id)
    participant_user_ids << root.user_id if root.user_id
    participant_user_ids.uniq!

    participant_user_ids.each do |uid|
      ActionCable.server.broadcast("user_feedbacks_#{uid}", payload)
    end
  end
end
