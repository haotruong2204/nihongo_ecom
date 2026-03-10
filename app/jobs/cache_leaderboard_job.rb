# frozen_string_literal: true

class CacheLeaderboardJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: 1

  CACHE_KEY = "leaderboard"
  CACHE_TTL = 10.minutes.to_i
  TOP_LIMIT = 10

  def perform
    users = build_leaderboard
    REDIS.setex(CACHE_KEY, CACHE_TTL, users.to_json)
    Rails.logger.info("[CacheLeaderboardJob] Cached #{users.size} leaderboard entries")
  rescue Redis::BaseError => e
    Rails.logger.error("[CacheLeaderboardJob] Redis error: #{e.message}")
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("[CacheLeaderboardJob] DB error: #{e.message}")
  end

  private

  def build_leaderboard
    # Dùng total_reviews_ever thay vì query review_logs trực tiếp
    # → không bị ảnh hưởng khi user xóa data để học lại
    active_users = User.where(is_banned: false)
                       .where("total_reviews_ever > 0")
                       .select(:id, :uid, :display_name, :photo_url, :is_premium, :premium_until,
                               :srs_cards_count, :total_reviews_ever)

    return [] if active_users.empty?

    active_user_ids = active_users.map(&:id)

    # Roadmap days completed per user
    roadmap_counts = RoadmapDayProgress.where(user_id: active_user_ids).group(:user_id).count

    # Current streak (vẫn cần query review_logs vì cần biết ngày gần nhất)
    streaks = calculate_streaks(active_user_ids)

    users_by_id = active_users.index_by(&:id)

    # Build entries sorted by total_reviews_ever desc
    entries = active_user_ids
      .map do |user_id|
        user = users_by_id[user_id]
        {
          uid: user.uid,
          displayName: user.display_name || "Anonymous",
          photoURL: user.photo_url,
          totalReviews: user.total_reviews_ever,
          srsCards: user.srs_cards_count,
          roadmapDays: roadmap_counts[user_id] || 0,
          streakDays: streaks[user_id] || 0,
          isPremium: user.premium?
        }
      end
      .sort_by { |e| -e[:totalReviews] }
      .first(TOP_LIMIT)

    # Assign ranks
    entries.each_with_index { |entry, i| entry[:rank] = i + 1 }

    entries
  end

  def calculate_streaks(user_ids)
    # Get review dates per user for the last 365 days
    since = 365.days.ago.beginning_of_day
    review_dates = ReviewLog.where(user_id: user_ids)
                            .where("reviewed_at >= ?", since)
                            .group(:user_id)
                            .pluck(:user_id, Arel.sql("GROUP_CONCAT(DISTINCT DATE(reviewed_at) ORDER BY DATE(reviewed_at) DESC)"))

    today = Date.current
    yesterday = today - 1

    review_dates.each_with_object({}) do |(user_id, dates_str), result|
      next unless dates_str

      dates = dates_str.split(",").map { |d| Date.parse(d) }

      # Streak must include today or yesterday to be "current"
      first_date = dates.first
      next unless first_date == today || first_date == yesterday

      streak = 1
      dates.each_cons(2) do |newer, older|
        if (newer - older).to_i == 1
          streak += 1
        else
          break
        end
      end

      result[user_id] = streak
    end
  end
end
