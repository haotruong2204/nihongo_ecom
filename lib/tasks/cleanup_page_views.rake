# frozen_string_literal: true

namespace :cleanup do
  desc "Delete page views older than 30 days"
  task page_views: :environment do
    count = PageView.where("last_visited_at < ?", 30.days.ago).delete_all

    puts "Cleanup complete: #{count} page views deleted"
  end
end
