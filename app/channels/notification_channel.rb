# frozen_string_literal: true

class NotificationChannel < ApplicationCable::Channel
  def subscribed
    if current_user.is_a?(Admin)
      stream_from "admin_notifications"
    elsif current_user.is_a?(User)
      stream_from "user_notifications_#{current_user.id}"
    else
      reject
    end
  end
end
