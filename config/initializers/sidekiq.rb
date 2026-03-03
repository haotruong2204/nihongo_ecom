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
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end
