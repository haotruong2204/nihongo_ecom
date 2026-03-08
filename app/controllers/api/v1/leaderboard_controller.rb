# frozen_string_literal: true

class Api::V1::LeaderboardController < ApplicationController
  include CommonResponse
  include ErrorCode

  respond_to :json

  def index
    cached = REDIS.get(CacheLeaderboardJob::CACHE_KEY)

    users = if cached
              JSON.parse(cached)
            else
              CacheLeaderboardJob.perform_now
              JSON.parse(REDIS.get(CacheLeaderboardJob::CACHE_KEY) || "[]")
            end

    data = {
      code: 200,
      message: I18n.t("api.common.success"),
      users: users,
      status: :ok
    }

    # Optional: return current user's rank if authenticated
    user = try_authenticate
    if user
      current_user_data = users.find { |u| u["uid"] == user.uid }
      data[:currentUser] = if current_user_data
                             current_user_data
                           else
                             build_current_user_stats(user, users)
                           end
    end

    response_success(data)
  end

  private

  def try_authenticate
    token = request.headers["Authorization"].to_s.split.last
    return nil unless token

    payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", nil), true, algorithm: "HS256").first
    user = User.find(payload["sub"])
    return nil unless user.jti == payload["jti"]

    user
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError, ActiveRecord::RecordNotFound
    nil
  end

  def build_current_user_stats(user, top_users)
    total_reviews = user.review_logs.count
    srs_cards = user.srs_cards.count
    roadmap_days = user.roadmap_day_progresses.count

    # Calculate rank: count users with more reviews + 1
    rank = ReviewLog.group(:user_id).having("COUNT(*) > ?", total_reviews).count.size + 1

    {
      "rank" => rank,
      "uid" => user.uid,
      "displayName" => user.display_name || "Anonymous",
      "photoURL" => user.photo_url,
      "totalReviews" => total_reviews,
      "srsCards" => srs_cards,
      "roadmapDays" => roadmap_days,
      "streakDays" => 0,
      "isPremium" => user.premium?
    }
  end
end
