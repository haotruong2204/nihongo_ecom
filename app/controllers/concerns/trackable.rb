# frozen_string_literal: true

module Trackable
  extend ActiveSupport::Concern

  included do
    before_action :track_request
  end

  private

  EXCLUDED_PATHS = %w[/api/v1/users/notifications].freeze

  def track_request
    return unless current_user
    return if EXCLUDED_PATHS.include?(request.path)

    user_id = current_user.id
    date = Date.current.to_s
    endpoint = "#{request.method} #{request.path}"
    daily_key = "req:#{user_id}:#{date}"
    burst_key = "req_burst:#{user_id}"

    daily_total, burst_count = increment_counters(daily_key, burst_key, endpoint)

    if burst_count > Settings.request_tracking.burst_limit
      AbuseDetectionService.handle_burst_exceeded(current_user, burst_count)
      too_many_requests
      return
    end

    if daily_total > Settings.request_tracking.daily_limit
      AbuseDetectionService.handle_daily_exceeded(current_user, daily_total)
    end
  rescue Redis::BaseError => e
    Rails.logger.warn("[Trackable] Redis error: #{e.message}")
  end

  def increment_counters(daily_key, burst_key, endpoint)
    daily_total = nil
    burst_count = nil

    REDIS.pipelined do |pipe|
      daily_total = pipe.hincrby(daily_key, "total", 1)
      pipe.hincrby(daily_key, endpoint, 1)
      pipe.expire(daily_key, Settings.request_tracking.redis_key_ttl)
      burst_count = pipe.incr(burst_key)
      pipe.expire(burst_key, Settings.request_tracking.burst_key_ttl)
    end

    [daily_total.value, burst_count.value]
  end
end
