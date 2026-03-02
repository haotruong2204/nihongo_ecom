# frozen_string_literal: true

class FlushRequestStatsJob < ApplicationJob
  queue_as :default

  def perform
    cursor = "0"
    flushed = 0

    loop do
      cursor, keys = REDIS.scan(cursor, match: "req:*:*", count: 100)
      keys.each { |key| flush_key(key) && flushed += 1 }
      break if cursor == "0"
    end

    Rails.logger.info("[FlushRequestStatsJob] Flushed #{flushed} keys")
  end

  private

  def flush_key(key)
    # Parse user_id and date from key format "req:{user_id}:{date}"
    parts = key.split(":")
    return false unless parts.length == 3

    user_id = parts[1].to_i
    date = parts[2]

    # RENAME to a temp key to avoid losing data during processing
    tmp_key = "#{key}:flush"
    begin
      REDIS.rename(key, tmp_key)
    rescue Redis::CommandError
      # Key may have expired between SCAN and RENAME
      return false
    end

    data = REDIS.hgetall(tmp_key)
    REDIS.del(tmp_key)

    return false if data.empty?

    total = data.delete("total").to_i
    endpoint_stats = data.transform_values(&:to_i)

    upsert_stat(user_id, date, total, endpoint_stats)
    true
  rescue StandardError => e
    Rails.logger.error("[FlushRequestStatsJob] Error flushing #{key}: #{e.message}")
    false
  end

  def upsert_stat(user_id, date, total, endpoint_stats)
    stat = DailyRequestStat.find_or_initialize_by(user_id: user_id, date: date)

    if stat.persisted?
      # Merge counts with existing record
      stat.total_requests += total
      existing = stat.endpoint_stats || {}
      endpoint_stats.each { |ep, count| existing[ep] = existing.fetch(ep, 0) + count }
      stat.endpoint_stats = existing
    else
      stat.total_requests = total
      stat.endpoint_stats = endpoint_stats
    end

    stat.save!
    AbuseDetectionService.flag_if_exceeded(stat)
  end
end
