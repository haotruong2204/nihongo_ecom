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
      "flush_request_stats" => {
        "cron" => "5 * * * *", # Every hour at minute 05
        "class" => "FlushRequestStatsJob",
        "queue" => "default",
        "description" => "Flush Redis request counters to daily_request_stats table"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end
