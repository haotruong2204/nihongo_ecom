# frozen_string_literal: true

class CleanupPageViewsJob < ApplicationJob
  queue_as :default

  def perform
    count = PageView.where("last_visited_at < ?", 30.days.ago).delete_all

    Rails.logger.info("[CleanupPageViewsJob] Deleted #{count} page views older than 30 days")
  end
end
