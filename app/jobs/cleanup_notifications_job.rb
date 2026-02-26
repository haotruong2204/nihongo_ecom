# frozen_string_literal: true

class CleanupNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 15.days.ago

    user_count = UserNotification.where("created_at < ?", cutoff).delete_all
    admin_count = AdminNotification.where("created_at < ?", cutoff).delete_all

    Rails.logger.info(
      "[CleanupNotificationsJob] User notifications: #{user_count}, Admin notifications: #{admin_count}"
    )
  end
end
