# frozen_string_literal: true

class CleanupInactiveUsersJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 15.days.ago
    inactive_users = User.where("last_login_at < ? OR last_login_at IS NULL", cutoff)

    deleted_srs = 0
    deleted_reviews = 0
    deleted_roadmap = 0

    inactive_users.find_each do |user|
      deleted_srs += user.srs_cards.delete_all
      deleted_reviews += user.review_logs.delete_all
      deleted_roadmap += user.roadmap_day_progresses.delete_all
    end

    Rails.logger.info(
      "[CleanupInactiveUsersJob] Users: #{inactive_users.count}, " \
      "SRS: #{deleted_srs}, Reviews: #{deleted_reviews}, Roadmap: #{deleted_roadmap}"
    )
  end
end
