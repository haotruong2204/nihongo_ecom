# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule = {
      "cleanup_inactive_users" => {
        "cron" => "0 1 * * *", # Every day at 1:00 AM
        "class" => "CleanupInactiveUsersJob",
        "queue" => "default",
        "description" => "Delete SRS, review logs, roadmap data for users inactive 15+ days"
      },
      "cleanup_notifications" => {
        "cron" => "0 2 * * *", # Every day at 2:00 AM
        "class" => "CleanupNotificationsJob",
        "queue" => "default",
        "description" => "Delete notifications older than 15 days"
      },
      "cache_dashboard_stats" => {
        "cron" => "*/10 * * * *", # Every 10 minutes
        "class" => "CacheDashboardStatsJob",
        "queue" => "default",
        "description" => "Pre-compute and cache dashboard statistics in Redis"
      },
      "expire_premium" => {
        "cron" => "0 0 * * *", # Every day at midnight
        "class" => "ExpirePremiumJob",
        "queue" => "default",
        "description" => "Set is_premium=false for users whose premium_until has passed"
      },
      "cache_leaderboard" => {
        "cron" => "*/10 * * * *", # Every 10 minutes
        "class" => "CacheLeaderboardJob",
        "queue" => "default",
        "description" => "Pre-compute and cache leaderboard rankings in Redis"
      }
    }

    # Xóa các cron jobs cũ không còn trong schedule
    Sidekiq::Cron::Job.all.each do |job|
      job.destroy unless schedule.key?(job.name)
    end

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end
