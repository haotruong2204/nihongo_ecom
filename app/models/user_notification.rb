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
    # Collect all participants: root author + all repliers, exclude reply author
    participant_ids = [parent_feedback.user_id].compact
    participant_ids += parent_feedback.replies.where.not(user_id: nil).pluck(:user_id)
    participant_ids = participant_ids.uniq - [reply.user_id]

    return if participant_ids.empty?

    link = parent_feedback.context_id.present? ? "/tango/#{parent_feedback.context_id}" : nil
    name = reply.display_name || "Ai đó"

    participant_ids.each do |uid|
      create(
        user_id: uid,
        title: "#{name} đã trả lời trong cuộc thảo luận của bạn",
        body: reply.text.truncate(100),
        link: link,
        notification_type: "feedback"
      )
    end
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
