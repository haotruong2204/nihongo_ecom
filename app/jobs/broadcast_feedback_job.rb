# frozen_string_literal: true

class BroadcastFeedbackJob < ApplicationJob
  queue_as :default

  def perform(feedback_id, event_type)
    feedback = Feedback.find_by(id: feedback_id)
    return unless feedback

    root = feedback.parent || feedback

    case event_type
    when "created"
      if feedback.user_id.nil? && feedback.email == "admin"
        broadcast_to_participants(feedback, root, :new_reply)
      else
        ActionCable.server.broadcast("admin_feedbacks", {
          type: "new_feedback",
          feedback: serialize_feedback(root)
        })
      end
    when "updated"
      payload = { type: "feedback_updated", feedback: serialize_feedback(root) }
      ActionCable.server.broadcast("admin_feedbacks", payload)
      ActionCable.server.broadcast("user_feedbacks_#{root.user_id}", payload) if root.user_id
    when "destroyed"
      payload = { type: "feedback_deleted", feedback_id: feedback_id, parent_id: feedback.parent_id }
      ActionCable.server.broadcast("admin_feedbacks", payload)
      ActionCable.server.broadcast("user_feedbacks_#{root.user_id}", payload) if root.user_id
    end
  end

  private

  def serialize_feedback(feedback)
    FeedbackSerializer.new(feedback, include: [:replies]).serializable_hash[:data]
  end

  def broadcast_to_participants(feedback, root, type)
    payload = { type: type, feedback: serialize_feedback(root) }

    participant_user_ids = root.replies.where.not(user_id: nil).distinct.pluck(:user_id)
    participant_user_ids << root.user_id if root.user_id
    participant_user_ids.uniq!

    participant_user_ids.each do |uid|
      ActionCable.server.broadcast("user_feedbacks_#{uid}", payload)
    end
  end
end
