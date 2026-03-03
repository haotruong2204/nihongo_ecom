# frozen_string_literal: true

class BroadcastNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id, event_type, metadata = {})
    case event_type
    when "created"
      notification = UserNotification.find_by(id: notification_id)
      return unless notification

      ActionCable.server.broadcast("user_notifications_#{notification.user_id}", {
        type: "new_notification",
        notification: UserNotificationSerializer.new(notification).serializable_hash[:data]
      })
    when "destroyed"
      user_id = metadata[:user_id] || metadata["user_id"]
      return unless user_id

      ActionCable.server.broadcast("user_notifications_#{user_id}", {
        type: "delete_notification",
        notification_id: notification_id
      })
    end
  end
end
