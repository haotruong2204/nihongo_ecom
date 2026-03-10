# frozen_string_literal: true

class Api::V1::Admins::DashboardController < Api::V1::BaseController

  def me
    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: AdminSerializer.new(current_admin).serializable_hash,
                       status: :ok
                     })
  end

  def analytics
    cached = REDIS.get(CacheDashboardStatsJob::CACHE_KEY)

    resource = if cached
                 JSON.parse(cached)
               else
                 CacheDashboardStatsJob.perform_now
                 JSON.parse(REDIS.get(CacheDashboardStatsJob::CACHE_KEY))
               end

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: resource,
                       status: :ok
                     })
  end

  def cache_sync
    # 1. Xóa tất cả cache theo pattern
    [
      CacheDashboardStatsJob::CACHE_KEY,
      CacheLeaderboardJob::CACHE_KEY,
      BlockedIp::CACHE_KEY
    ].each { |key| REDIS.del(key) }

    # Xóa toàn bộ user_stats (xây lại theo yêu cầu)
    keys = REDIS.keys("user_stats:*")
    REDIS.del(*keys) if keys.any?

    # 2. Rebuild các cache dùng chung — chạy async để không block request
    CacheDashboardStatsJob.perform_later
    CacheLeaderboardJob.perform_later
    BlockedIp.refresh_cache! # Nhẹ, chạy sync được

    response_success({
                       code: 200,
                       message: "Đã sync toàn bộ cache thành công",
                       status: :ok
                     })
  end
end
