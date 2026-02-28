# frozen_string_literal: true

namespace :cleanup do
  desc "Delete SRS cards, review logs, and roadmap progresses for users inactive for 15+ days"
  task inactive_users: :environment do
    cutoff = 15.days.ago
    inactive_user_ids = User.where("last_login_at < ? OR last_login_at IS NULL", cutoff).ids
    count = inactive_user_ids.size

    puts "Found #{count} users inactive since #{cutoff.strftime('%Y-%m-%d')}..."

    deleted_srs = SrsCard.where(user_id: inactive_user_ids).delete_all
    deleted_reviews = ReviewLog.where(user_id: inactive_user_ids).delete_all
    deleted_roadmap = RoadmapDayProgress.where(user_id: inactive_user_ids).delete_all

    puts "Cleanup complete:"
    puts "  Users affected:           #{count}"
    puts "  SRS cards deleted:        #{deleted_srs}"
    puts "  Review logs deleted:      #{deleted_reviews}"
    puts "  Roadmap progresses deleted: #{deleted_roadmap}"
  end
end
