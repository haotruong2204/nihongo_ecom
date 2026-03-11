# frozen_string_literal: true

class Api::V1::Admins::RevenueController < Api::V1::BaseController
  def index
    total_revenue = RevenueRecord.sum(:amount)

    today_start     = Time.current.beginning_of_day
    yesterday_start = 1.day.ago.beginning_of_day
    yesterday_end   = today_start

    this_month_start = Time.current.beginning_of_month
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end   = this_month_start

    today_revenue     = RevenueRecord.where(created_at: today_start..).sum(:amount)
    yesterday_revenue = RevenueRecord.where(created_at: yesterday_start...yesterday_end).sum(:amount)

    this_month_revenue = RevenueRecord.where(created_at: this_month_start..).sum(:amount)
    last_month_revenue = RevenueRecord.where(created_at: last_month_start...last_month_end).sum(:amount)

    monthly_count = RevenueRecord.where(plan_type: "monthly").count
    yearly_count  = RevenueRecord.where(plan_type: "yearly").count

    # Revenue per day for the last 30 days
    daily_chart = 29.downto(0).map do |i|
      day_start = i.days.ago.beginning_of_day
      day_end   = day_start.end_of_day
      {
        day:     day_start.strftime("%d/%m"),
        revenue: RevenueRecord.where(created_at: day_start..day_end).sum(:amount)
      }
    end

    # Revenue per month for the last 12 months
    monthly_chart = 11.downto(0).map do |i|
      month_start = i.months.ago.beginning_of_month
      month_end   = month_start.end_of_month
      {
        month:   month_start.strftime("%b %Y"),
        revenue: RevenueRecord.where(created_at: month_start..month_end).sum(:amount)
      }
    end

    recent = RevenueRecord.includes(:user).order(created_at: :desc).limit(20)
    recent_transactions = recent.map do |r|
      {
        id:            r.id,
        email:         r.user.email,
        display_name:  r.user.display_name,
        photo_url:     r.user.photo_url,
        amount:        r.amount,
        plan_type:     r.plan_type,
        premium_until: r.premium_until,
        created_at:    r.created_at
      }
    end

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       revenue: {
                         total_revenue:,
                         today_revenue:,
                         yesterday_revenue:,
                         this_month_revenue:,
                         last_month_revenue:,
                         monthly_count:,
                         yearly_count:,
                         daily_chart:,
                         monthly_chart:,
                         recent_transactions:
                       },
                       status: :ok
                     })
  end
end
