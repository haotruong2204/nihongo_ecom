# frozen_string_literal: true

class Api::V1::Admins::DashboardController < Api::V1::BaseController
  include OnlinePresence

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

    resource["widgets"] ||= {}
    resource["widgets"]["online_users"] = online_users_count

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: resource,
                       status: :ok
                     })
  end
end
