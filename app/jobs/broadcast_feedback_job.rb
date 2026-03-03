# frozen_string_literal: true

class BroadcastFeedbackJob < ApplicationJob
  queue_as :default

  def perform(feedback_id, event_type, metadata = {})
    if event_type == "destroyed"
      broadcast_destroyed(feedback_id, metadata)
      return
    end

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
    end
  end

  private

  def broadcast_destroyed(feedback_id, metadata)
    parent_id = metadata[:parent_id] || metadata["parent_id"]
    user_id = metadata[:user_id] || metadata["user_id"]

    # Nếu xóa reply → tìm root để broadcast updated state
    if parent_id
      root = Feedback.find_by(id: parent_id)
      if root
        payload = { type: "feedback_updated", feedback: serialize_feedback(root) }
        ActionCable.server.broadcast("admin_feedbacks", payload)
        ActionCable.server.broadcast("user_feedbacks_#{root.user_id}", payload) if root.user_id
        return
      end
    end

    # Xóa root feedback
    payload = { type: "feedback_deleted", feedback_id: feedback_id, parent_id: parent_id }
    ActionCable.server.broadcast("admin_feedbacks", payload)
    ActionCable.server.broadcast("user_feedbacks_#{user_id}", payload) if user_id
  end

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
