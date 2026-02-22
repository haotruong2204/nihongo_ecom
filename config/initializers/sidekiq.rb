# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule = {
      "cleanup_inactive_users" => {
        "cron" => "0 1 * * *", # Every day at 1:00 AM
        "class" => "CleanupInactiveUsersJob",
        "queue" => "default",
        "description" => "Delete SRS, review logs, roadmap data for users inactive 15+ days"
      }
    }

    Sidekiq::Cron::Job.load_from_hash!(schedule)
  end
end
