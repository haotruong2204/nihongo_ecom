# frozen_string_literal: true

class BroadcastNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id, event_type)
    notification = UserNotification.find_by(id: notification_id)
    return unless notification

    case event_type
    when "created"
      ActionCable.server.broadcast("user_notifications_#{notification.user_id}", {
        type: "new_notification",
        notification: UserNotificationSerializer.new(notification).serializable_hash[:data]
      })
    when "destroyed"
      ActionCable.server.broadcast("user_notifications_#{notification.user_id}", {
        type: "delete_notification",
        notification_id: notification_id
      })
    end
  end
end
