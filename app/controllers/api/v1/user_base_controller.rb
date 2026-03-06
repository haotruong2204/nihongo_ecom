# frozen_string_literal: true

class Api::V1::UserBaseController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!
  after_action :track_request_rate
  include CommonResponse
  include ErrorCode

  respond_to :json

  def authenticate_user!
    token = request.headers["Authorization"].to_s.split.last
    return unauthorized("token_missing") unless token

    begin
      payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", nil), true, algorithm: "HS256").first
      user = User.find(payload["sub"])
      return unauthorized("device_conflict") unless user.jti == payload["jti"]

      @current_user = user
    rescue JWT::ExpiredSignature
      unauthorized("token_expired")
    rescue JWT::DecodeError, JWT::VerificationError, ActiveRecord::RecordNotFound
      unauthorized("token_invalid")
    end
  end

  attr_reader :current_user

  private

  REVIEW_LIMIT = 500        # ~7s/card sustained = learning too fast
  SPAM_LIMIT = 1500         # write requests/hour = spam/abuse
  RATE_PERIOD = 1.hour
  ALERT_COOLDOWN = 24.hours

  def track_request_rate
    return unless current_user
    return if request.get? || request.head?

    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    uid = current_user.id

    # Track all write requests for spam detection
    spam_key = "user_write_count:#{uid}"
    spam_count = redis.incr(spam_key)
    redis.expire(spam_key, RATE_PERIOD.to_i) if spam_count == 1

    # Track SRS reviews separately for "learning too fast" detection
    is_review = controller_name == "review_logs" && action_name == "create"
    if is_review
      review_key = "user_review_count:#{uid}"
      review_count = redis.incr(review_key)
      redis.expire(review_key, RATE_PERIOD.to_i) if review_count == 1

      if review_count == REVIEW_LIMIT
        cooldown_key = "learning_fast_sent:#{uid}"
        unless redis.exists?(cooldown_key)
          redis.set(cooldown_key, 1, ex: ALERT_COOLDOWN.to_i)
          UserNotification.notify_learning_too_fast(current_user)
        end
      end
    end

    if spam_count == SPAM_LIMIT
      cooldown_key = "abuse_alert_sent:#{uid}"
      unless redis.exists?(cooldown_key)
        redis.set(cooldown_key, 1, ex: ALERT_COOLDOWN.to_i)

        AdminNotification.create(
          title: "Spam: #{current_user.email} — #{SPAM_LIMIT} writes/giờ",
          body: "User ##{uid} (#{current_user.email}) đã đạt #{SPAM_LIMIT} write requests trong 1 giờ. Có thể là bot hoặc scraper.",
          link: "/users/#{uid}",
          notification_type: "abuse_alert",
          created_by: "system"
        )

        UserNotification.notify_spam_detected(current_user)
      end
    end
  rescue Redis::BaseError => e
    Rails.logger.error("[TrackRequestRate] Redis error: #{e.message}")
  end

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
