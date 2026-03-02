# frozen_string_literal: true

class Api::V1::Admins::RequestStatsController < Api::V1::BaseController
  include Pagy::Backend

  def index
    q = DailyRequestStat.ransack(params[:q])
    pagy, stats = pagy(q.result.recent, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: DailyRequestStatSerializer.new(stats).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def realtime
    user_id = params[:user_id]
    date = Date.current.to_s
    key = "req:#{user_id}:#{date}"

    data = REDIS.hgetall(key)
    total = data.delete("total").to_i
    endpoints = data.transform_values(&:to_i)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: { user_id: user_id.to_i, date: date, total_requests: total, endpoint_stats: endpoints },
      status: :ok
                     })
  rescue Redis::BaseError => e
    Rails.logger.warn("[RequestStats] Redis error: #{e.message}")
    response_error({}, 500, "Redis unavailable")
  end

  def summary
    today = Date.current
    last_7_days = today - 6

    stats = DailyRequestStat.where(date: last_7_days..today)

    top_users = stats.group(:user_id)
                     .select("user_id, SUM(total_requests) as total")
                     .order("total DESC")
                     .limit(10)
                     .map { |s| { user_id: s.user_id, total: s.total.to_i } }

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: {
        period: { from: last_7_days, to: today },
        total_requests: stats.sum(:total_requests),
        flagged_count: stats.flagged.count,
        unique_users: stats.distinct.count(:user_id),
        top_users: top_users
      },
      status: :ok
                     })
  end

  private

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
