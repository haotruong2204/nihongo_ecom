# frozen_string_literal: true

namespace :cleanup do
  desc "Delete notifications older than 15 days"
  task notifications: :environment do
    cutoff = 15.days.ago

    user_count = UserNotification.where("created_at < ?", cutoff).delete_all
    admin_count = AdminNotification.where("created_at < ?", cutoff).delete_all

    puts "Cleanup complete:"
    puts "  User notifications deleted:  #{user_count}"
    puts "  Admin notifications deleted: #{admin_count}"
  end
end
