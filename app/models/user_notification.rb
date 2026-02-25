# frozen_string_literal: true

class UserNotification < ApplicationRecord
  belongs_to :user

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  validates :title, presence: true

  def self.notify_feedback_replied(feedback, reply)
    return unless feedback.user_id

    create(
      user_id: feedback.user_id,
      title: "Góp ý của bạn đã được phản hồi",
      body: reply.text.truncate(100),
      link: feedback.context_id.present? ? "/tango/#{feedback.context_id}" : nil,
      notification_type: "feedback"
    )
  end

  def self.notify_user_replied(parent_feedback, reply)
    return unless parent_feedback.user_id
    return if parent_feedback.user_id == reply.user_id

    create(
      user_id: parent_feedback.user_id,
      title: "#{reply.display_name || 'Ai đó'} đã trả lời góp ý của bạn",
      body: reply.text.truncate(100),
      link: parent_feedback.context_id.present? ? "/tango/#{parent_feedback.context_id}" : nil,
      notification_type: "feedback"
    )
  end

  def self.notify_feedback_approved(feedback)
    return unless feedback.user_id

    create(
      user_id: feedback.user_id,
      title: "Góp ý của bạn đã được duyệt",
      body: feedback.text.truncate(100),
      link: feedback.context_id.present? ? "/tango/#{feedback.context_id}" : nil,
      notification_type: "feedback"
    )
  end
end
