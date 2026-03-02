# frozen_string_literal: true

class AbuseDetectionService
  def self.handle_daily_exceeded(user, count)
    # Only notify once per user per day using Redis SET NX
    notification_key = "abuse_notified:#{user.id}:#{Date.current}"
    return unless REDIS.set(notification_key, "1", nx: true, ex: 86_400)

    AdminNotification.create(
      title: "Abuse alert: #{user.email} exceeded daily limit",
      body: "User #{user.email} (ID: #{user.id}) made #{count} requests today, exceeding the daily limit of #{Settings.request_tracking.daily_limit}.",
      notification_type: "abuse_alert",
      created_by: "system"
    )
  end

  def self.handle_burst_exceeded(user, count)
    Rails.logger.warn(
      "[AbuseDetection] Burst limit exceeded: user=#{user.id} email=#{user.email} count=#{count}/min"
    )
  end

  def self.flag_if_exceeded(daily_stat)
    limit = Settings.request_tracking.daily_limit
    return unless daily_stat.total_requests > limit

    daily_stat.update(
      flagged: true,
      flag_reason: "Exceeded daily limit: #{daily_stat.total_requests}/#{limit} requests"
    )
  end
end
