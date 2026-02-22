# frozen_string_literal: true

namespace :cleanup do
  desc "Delete SRS cards, review logs, and roadmap progresses for users inactive for 15+ days"
  task inactive_users: :environment do
    cutoff = 15.days.ago
    inactive_users = User.where("last_login_at < ? OR last_login_at IS NULL", cutoff)
    count = inactive_users.count

    puts "Found #{count} users inactive since #{cutoff.strftime('%Y-%m-%d')}..."

    deleted_srs = 0
    deleted_reviews = 0
    deleted_roadmap = 0

    inactive_users.find_each do |user|
      srs = user.srs_cards.delete_all
      reviews = user.review_logs.delete_all
      roadmap = user.roadmap_day_progresses.delete_all

      deleted_srs += srs
      deleted_reviews += reviews
      deleted_roadmap += roadmap
    end

    puts "Cleanup complete:"
    puts "  Users affected:           #{count}"
    puts "  SRS cards deleted:        #{deleted_srs}"
    puts "  Review logs deleted:      #{deleted_reviews}"
    puts "  Roadmap progresses deleted: #{deleted_roadmap}"
  end
end
