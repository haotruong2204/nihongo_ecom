# frozen_string_literal: true

class CleanupInactiveUsersJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 5.days.ago
    inactive_user_ids = User
      .where("last_login_at < ? OR last_login_at IS NULL", cutoff)
      .where(is_premium: false)
      .ids

    return if inactive_user_ids.empty?

    deleted_srs = 0
    deleted_reviews = 0
    deleted_roadmap = 0

    # Delete in batches to avoid long-running transactions and deadlocks
    inactive_user_ids.each_slice(100) do |batch_ids|
      deleted_srs += SrsCard.where(user_id: batch_ids).delete_all
      deleted_reviews += ReviewLog.where(user_id: batch_ids).delete_all
      deleted_roadmap += RoadmapDayProgress.where(user_id: batch_ids).delete_all
    end

    Rails.logger.info(
      "[CleanupInactiveUsersJob] Users: #{inactive_user_ids.size}, " \
      "SRS: #{deleted_srs}, Reviews: #{deleted_reviews}, Roadmap: #{deleted_roadmap}"
    )
  end
end
