# frozen_string_literal: true

class AdminNotification < ApplicationRecord
  NOTIFICATION_TYPES = %w[feedback new_feature upgrade_success maintenance welcome warning abuse_alert].freeze
  CREATED_BY_OPTIONS = %w[system admin].freeze

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_admins

  validates :title, presence: true
  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }
  validates :created_by, inclusion: { in: CREATED_BY_OPTIONS }

  def self.ransackable_attributes _auth_object = nil
    %w[title notification_type read created_at created_by]
  end

  def self.create_for_feedback feedback
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

  private

  def broadcast_to_admins
    ActionCable.server.broadcast("admin_notifications", {
                                   type: "new_notification",
      notification: AdminNotificationSerializer.new(self).serializable_hash[:data]
                                 })
  end
end
