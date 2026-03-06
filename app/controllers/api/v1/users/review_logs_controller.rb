# frozen_string_literal: true

class Api::V1::Users::ReviewLogsController < Api::V1::UserBaseController
  before_action :set_review_log, only: [:show]

  def index
    q = current_user.review_logs.ransack(params[:q])
    pagy, review_logs = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: ReviewLogSerializer.new(review_logs).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: ReviewLogSerializer.new(@review_log).serializable_hash,
      status: :ok
                     })
  end

  def create
    review_log = current_user.review_logs.build(review_log_params)

    if review_log.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: ReviewLogSerializer.new(review_log).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(review_log)
    end
  end

  # GET /api/v1/users/review_logs/stats?type=all|kanji|vocab
  def stats
    scope = current_user.review_logs
    scope = apply_type_filter(scope)

    now = Time.current
    today_start = now.beginning_of_day
    week_start = now.beginning_of_week(:monday)
    month_start = now.beginning_of_month

    total = scope.count
    today = scope.where(reviewed_at: today_start..now).count
    this_week = scope.where(reviewed_at: week_start..now).count
    this_month = scope.where(reviewed_at: month_start..now).count

    avg_duration_ms = scope.where("duration_ms > 0").average(:duration_ms)&.round

    # Rating breakdown
    rating_counts = scope.group(:rating).count
    rating_breakdown = {
      again: rating_counts[1] || 0,
      hard: rating_counts[2] || 0,
      good: rating_counts[3] || 0,
      easy: rating_counts[4] || 0
    }

    # Daily counts for streak + avg_per_day
    daily_counts = scope.group("DATE(reviewed_at)").count
    days_with_reviews = daily_counts.size
    avg_per_day = days_with_reviews > 0 ? (total.to_f / days_with_reviews).round : 0

    # Streak: consecutive days counting back from today
    streak = 0
    check_date = now.to_date
    loop do
      if daily_counts[check_date] && daily_counts[check_date] > 0
        streak += 1
        check_date -= 1.day
      else
        break
      end
    end

    # Last 7 days
    last_7_days = (0..6).map { |i|
      d = (now - i.days).to_date
      { date: d.to_s, count: daily_counts[d] || 0 }
    }.reverse

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: {
        total: total,
        today: today,
        this_week: this_week,
        this_month: this_month,
        streak: streak,
        avg_per_day: avg_per_day,
        avg_duration_ms: avg_duration_ms,
        rating_breakdown: rating_breakdown,
        last_7_days: last_7_days
      },
      status: :ok
    })
  end

  private

  def set_review_log
    @review_log = current_user.review_logs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def review_log_params
    params.require(:review_log).permit(:kanji, :rating, :interval_before, :interval_after, :reviewed_at, :duration_ms)
  end

  def apply_type_filter(scope)
    case params[:type]
    when "kanji"
      scope.where("CHAR_LENGTH(kanji) = 1")
    when "vocab"
      scope.where("CHAR_LENGTH(kanji) > 1")
    else
      scope
    end
  end
end
