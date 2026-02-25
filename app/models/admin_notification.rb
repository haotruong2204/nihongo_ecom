# frozen_string_literal: true

class AdminNotification < ApplicationRecord
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  validates :title, presence: true

  def self.create_for_feedback(feedback)
    is_reply = feedback.parent_id.present?
    name = feedback.display_name || feedback.email
    feedback_id = is_reply ? feedback.parent_id : feedback.id

    create(
      title: is_reply ? "Phản hồi mới từ #{name}" : "Góp ý mới từ #{name}",
      body: feedback.text.truncate(100),
      link: "/feedback?id=#{feedback_id}",
      notification_type: "feedback"
    )
  end
end
