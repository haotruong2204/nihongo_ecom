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

  REQUEST_LIMIT = 500
  REQUEST_PERIOD = 1.hour
  ABUSE_ALERT_COOLDOWN = 24.hours

  def track_request_rate
    return unless current_user

    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    key = "user_req_count:#{current_user.id}"

    count = redis.incr(key)
    redis.expire(key, REQUEST_PERIOD.to_i) if count == 1

    daily_key = "daily_req_count:#{Date.today}"
    redis.incr(daily_key)
    redis.expire(daily_key, 48.hours.to_i) if redis.ttl(daily_key) < 0

    if count == REQUEST_LIMIT
      cooldown_key = "abuse_alert_sent:#{current_user.id}"
      already_alerted = redis.exists?(cooldown_key)

      unless already_alerted
        redis.set(cooldown_key, 1, ex: ABUSE_ALERT_COOLDOWN.to_i)

        AdminNotification.create(
          title: "Cảnh báo: #{current_user.email} đã gửi #{REQUEST_LIMIT} request/giờ",
          body: "User ##{current_user.id} (#{current_user.email}) đã đạt #{REQUEST_LIMIT} requests trong 1 giờ. Có thể là hành vi bất thường.",
          link: "/users/#{current_user.id}",
          notification_type: "abuse_alert",
          created_by: "system"
        )

        UserNotification.notify_learning_too_fast(current_user)
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
