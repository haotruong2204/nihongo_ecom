# frozen_string_literal: true

class BlockedIp < ApplicationRecord
  belongs_to :blocked_by, class_name: "Admin", optional: true

  validates :ip_address, presence: true, uniqueness: true

  scope :recent, -> { order(created_at: :desc) }

  # Cache blocked IPs in Redis for fast Rack::Attack lookup
  CACHE_KEY = "blocked_ips_set"

  after_commit :refresh_cache

  def self.blocked?(ip)
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    redis.sismember(CACHE_KEY, ip)
  rescue Redis::BaseError
    # Fallback to DB if Redis is down
    exists?(ip_address: ip)
  end

  def self.refresh_cache!
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    redis.del(CACHE_KEY)
    ips = pluck(:ip_address)
    redis.sadd(CACHE_KEY, ips) if ips.any?
  rescue Redis::BaseError => e
    Rails.logger.error("[BlockedIp] Redis error: #{e.message}")
  end

  def self.ransackable_attributes _auth_object = nil
    %w[ip_address reason created_at]
  end

  private

  def refresh_cache
    self.class.refresh_cache!
  end
end
