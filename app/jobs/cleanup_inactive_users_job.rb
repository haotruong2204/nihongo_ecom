# frozen_string_literal: true

class CleanupInactiveUsersJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 15.days.ago
    inactive_user_ids = User.where("last_login_at < ? OR last_login_at IS NULL", cutoff).ids

    deleted_srs = SrsCard.where(user_id: inactive_user_ids).delete_all
    deleted_reviews = ReviewLog.where(user_id: inactive_user_ids).delete_all
    deleted_roadmap = RoadmapDayProgress.where(user_id: inactive_user_ids).delete_all

    Rails.logger.info(
      "[CleanupInactiveUsersJob] Users: #{inactive_user_ids.size}, " \
      "SRS: #{deleted_srs}, Reviews: #{deleted_reviews}, Roadmap: #{deleted_roadmap}"
    )
  end
end
