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
    today = Time.current.beginning_of_day

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: {
                         widgets: build_widgets(today),
                         record_stats: build_record_stats(today),
                         daily_activity: build_daily_activity,
                         srs_distribution: build_srs_distribution,
                         top_pages: build_top_pages,
                         jlpt_performance: build_jlpt_performance,
                         recent_feedbacks: build_recent_feedbacks,
                         recent_activities: build_recent_activities,
                         feature_usage: build_feature_usage
                       },
                       status: :ok
                     })
  end

  private

  def build_widgets(today)
    {
      total_users: User.count,
      premium_users: User.where(is_premium: true).count,
      new_users_today: User.where("created_at >= ?", today).count,
      logged_in_users: LoginActivity.where("created_at >= ?", today).select(:user_id).distinct.count
    }
  end

  def build_record_stats(today)
    tables = [ReviewLog, LoginActivity, SrsCard, Feedback,
              RoadmapDayProgress, TangoLessonProgress, JlptTestResult,
              CustomVocabItem, Contact]

    records_today = tables.sum { |t| t.where("created_at >= ?", today).count }
    records_today += PageView.where("last_visited_at >= ?", today).count
    total_records = tables.sum(&:count) + PageView.count

    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    requests_today = redis.get("daily_req_count:#{Date.today}").to_i

    { records_today:, total_records:, requests_today: }
  end

  def build_daily_activity
    start = 30.days.ago.beginning_of_day
    dates = (0..29).map { |i| (start + i.days).to_date }
    labels = dates.map { |d| d.strftime("%m/%d/%Y") }

    reviews = ReviewLog.where("reviewed_at >= ?", start).group("DATE(reviewed_at)").count
    new_users = User.where("created_at >= ?", start).group("DATE(created_at)").count
    logins = LoginActivity.where("created_at >= ?", start).group("DATE(created_at)").count

    {
      labels: labels,
      series: [
        { name: "Reviews", type: "column", fill: "solid", data: dates.map { |d| reviews[d] || 0 } },
        { name: "New Users", type: "area", fill: "gradient", data: dates.map { |d| new_users[d] || 0 } },
        { name: "Logins", type: "line", fill: "solid", data: dates.map { |d| logins[d] || 0 } }
      ]
    }
  end

  def build_srs_distribution
    counts = SrsCard.group(:state).count
    state_labels = { 0 => "New", 1 => "Learning", 2 => "Review", 3 => "Relearning" }

    state_labels.map do |key, label|
      { label: label, value: counts[key] || counts[label.downcase] || 0 }
    end
  end

  def build_top_pages
    PageView.select("url, SUM(view_count) AS total_views")
            .group(:url)
            .order("total_views DESC")
            .limit(10)
            .map { |pv| { label: pv.url, value: pv.total_views.to_i } }
  end

  def build_jlpt_performance
    levels = %w[N5 N4 N3 N2 N1]

    avg_scores = []
    pass_rates = []
    tests_taken = []

    levels.each do |level|
      results = JlptTestResult.for_level(level)
      total = results.count
      passed = results.passed.count

      if total > 0
        avg_score = results.average("(correct_count * 100.0) / NULLIF(total_questions, 0)").to_f.round(1)
        pass_rate = (passed * 100.0 / total).round(1)
      else
        avg_score = 0
        pass_rate = 0
      end

      avg_scores << avg_score
      pass_rates << pass_rate
      tests_taken << [total, 100].min # cap at 100 for radar display
    end

    {
      categories: levels,
      series: [
        { name: "Avg Score %", data: avg_scores },
        { name: "Pass Rate %", data: pass_rates },
        { name: "Tests Taken", data: tests_taken }
      ]
    }
  end

  def build_recent_feedbacks
    Feedback.roots.recent.limit(5).map do |fb|
      {
        id: fb.id.to_s,
        title: fb.display_name.presence || fb.email.to_s.split("@").first || "Anonymous",
        description: fb.text.to_s.truncate(100),
        postedAt: fb.created_at,
        coverUrl: fb.photo_url.presence || "/assets/icons/glass/ic_glass_message.png"
      }
    end
  end

  def build_recent_activities
    AdminNotification.recent.limit(5).map do |notif|
      {
        id: notif.id.to_s,
        title: notif.title,
        time: notif.created_at,
        type: notif.notification_type
      }
    end
  end

  def build_feature_usage
    [
      { value: "srs", label: "SRS Cards", total: SrsCard.count, icon: "mdi:cards-outline" },
      { value: "roadmap", label: "Roadmap Progress", total: RoadmapDayProgress.count, icon: "mdi:road-variant" },
      { value: "tango", label: "Tango Lessons", total: TangoLessonProgress.count, icon: "mdi:book-open-variant" },
      { value: "jlpt", label: "JLPT Results", total: JlptTestResult.count, icon: "mdi:certificate-outline" }
    ]
  end
end
