# frozen_string_literal: true

class UserNotification < ApplicationRecord
  NOTIFICATION_TYPES = %w[feedback new_feature upgrade_success maintenance welcome warning].freeze
  CREATED_BY_OPTIONS = %w[system admin].freeze

  belongs_to :user
  belongs_to :feedback, optional: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_user
  after_destroy_commit :broadcast_delete_to_user

  validates :title, presence: true
  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }
  validates :created_by, inclusion: { in: CREATED_BY_OPTIONS }

  def self.ransackable_attributes _auth_object = nil
    %w[title notification_type read created_at user_id created_by]
  end

  def self.ransackable_associations _auth_object = nil
    %w[user]
  end

  def self.create_welcome user
    create(
      user_id: user.id,
      title: "Chào mừng đến với website!",
      body: "Cảm ơn bạn đã đăng ký. Chúc bạn học tiếng Nhật vui vẻ!",
      notification_type: "welcome",
      created_by: "system"
    )
  end

  def self.notify_user_replied parent_feedback, reply
    # Collect all participants: root author + all repliers, exclude reply author
    participant_ids = [parent_feedback.user_id].compact
    participant_ids += parent_feedback.replies.where.not(user_id: nil).pluck(:user_id)
    participant_ids = participant_ids.uniq
    participant_ids -= [reply.user_id] if reply.user_id
    return if participant_ids.empty?

    link = parent_feedback.context_id.present? ? "/tango/#{parent_feedback.context_id}" : nil
    name = reply.user_id.nil? ? "Quản trị viên" : (reply.display_name || "Ai đó")

    participant_ids.each do |uid|
      create(
        user_id: uid,
        title: "#{name} đã trả lời trong cuộc thảo luận của bạn",
        body: reply.text.truncate(100),
        link: link,
        feedback_id: reply.id,
        notification_type: "feedback"
      )
    end
  end

  def self.notify_feedback_approved feedback
    return unless feedback.user_id

    create(
      user_id: feedback.user_id,
      title: "Góp ý của bạn đã được duyệt",
      body: feedback.text.truncate(100),
      link: feedback.context_id.present? ? "/tango/#{feedback.context_id}" : nil,
      feedback_id: feedback.id,
      notification_type: "feedback"
    )
  end

  private

  def broadcast_to_user
    ActionCable.server.broadcast("user_notifications_#{user_id}", {
                                   type: "new_notification",
      notification: UserNotificationSerializer.new(self).serializable_hash[:data]
                                 })
  end

  def broadcast_delete_to_user
    ActionCable.server.broadcast("user_notifications_#{user_id}", { type: "delete_notification", notification_id: id })
  end
end
