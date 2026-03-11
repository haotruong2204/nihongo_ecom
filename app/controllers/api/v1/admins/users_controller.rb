# frozen_string_literal: true

class Api::V1::Admins::UsersController < Api::V1::BaseController
  include Pagy::Backend
  include UserCounterSync

  before_action :set_user, only: [:show, :update, :destroy, :recalculate_counters]

  def index
    q = User.ransack(params[:q])
    results = q.sorts.empty? ? q.result.order(created_at: :desc) : q.result

    if params[:ip].present?
      results = results.joins(:login_activities).where(login_activities: { ip_address: params[:ip] }).distinct
    end

    pagy, users = pagy(results, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserSerializer.new(users).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    cache_key = "user_stats:#{@user.id}"
    cached = REDIS.get(cache_key)

    if cached
      parsed = JSON.parse(cached)
      stats = parsed["stats"]
      learning_summary = parsed["learning_summary"]
    else
      stats = {
        srs_cards_count: @user.srs_cards.count,
        kanji_srs_cards_count: @user.srs_cards.where(reading: [nil, ""]).count,
        vocab_srs_cards_count: @user.srs_cards.where.not(reading: [nil, ""]).count,
        review_logs_count: @user.review_logs.count,
        vocab_sets_count: @user.vocab_sets.count,
        custom_vocab_items_count: @user.custom_vocab_items.count,
        roadmap_day_progresses_count: @user.roadmap_day_progresses.count,
        tango_lesson_progresses_count: @user.tango_lesson_progresses.count,
        jlpt_test_results_count: @user.jlpt_test_results.count,
        login_activities_count: @user.login_activities.count,
        page_views_count: @user.page_views.count
      }
      learning_summary = build_learning_summary

      REDIS.setex(cache_key, 5.minutes.to_i, { stats: stats, learning_summary: learning_summary }.to_json)
    end

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserSerializer.new(@user).serializable_hash,
      stats: stats,
      learning_summary: learning_summary,
      status: :ok
                     })
  end

  def update
    was_banned = @user.is_banned
    was_premium = @user.is_premium
    if @user.update(user_params)
      # If admin just banned user → invalidate JWT to force logout on next request
      if @user.is_banned && !was_banned
        @user.update!(jti: SecureRandom.uuid)
      end

      # If admin just unbanned user → clear all login history so device count resets from scratch
      if was_banned && !@user.is_banned
        @user.login_activities.delete_all
      end

      # If admin just upgraded user to premium → reset slot locks + clear device history + send notification + record revenue
      if @user.is_premium && !was_premium
        @user.update_columns(kanji_slots_locked: false, vocab_slots_locked: false)
        @user.login_activities.delete_all
        UserNotification.notify_upgrade_success(@user)
        RevenueRecord.record_upgrade(@user)
      end

      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: UserSerializer.new(@user).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@user)
    end
  end

  def destroy
    REDIS.del("user_stats:#{@user.id}")
    @user.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  def recalculate_counters
    sync_user_counters(@user)
    response_success({
      code: 200,
      message: "Đã đồng bộ số liệu cho user ##{@user.id}",
      status: :ok
    })
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def user_params
    params.require(:user).permit(:is_premium, :premium_until, :is_banned, :banned_reason)
  end

  def build_learning_summary
    srs = @user.srs_cards
    reviews = @user.review_logs
    roadmap = @user.roadmap_day_progresses

    # SRS breakdown by state
    srs_by_state = srs.group(:state).count
    srs_total = srs.count

    # Roadmap progress
    roadmap_completed = roadmap.count
    last_day = roadmap.order(day: :desc).pick(:day)
    all_kanji = roadmap.pluck(:kanji_learned).flatten.uniq

    # Review activity
    reviews_today = reviews.where(reviewed_at: Time.current.all_day).count
    reviews_7d = reviews.where(reviewed_at: 7.days.ago..).count
    reviews_30d = reviews.where(reviewed_at: 30.days.ago..).count
    last_review = reviews.order(reviewed_at: :desc).pick(:reviewed_at)

    # SRS due
    due_now = srs.where(due_date: ..Time.current).count

    {
      roadmap: {
        days_completed: roadmap_completed,
        last_day: last_day,
        total_kanji_learned: all_kanji.size
      },
      srs: {
        total: srs_total,
        new_card: srs_by_state[0] || 0,
        learning: srs_by_state[1] || 0,
        review: srs_by_state[2] || 0,
        relearning: srs_by_state[3] || 0,
        due_now: due_now
      },
      reviews: {
        total: reviews.count,
        today: reviews_today,
        last_7_days: reviews_7d,
        last_30_days: reviews_30d,
        last_review_at: last_review
      }
    }
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
