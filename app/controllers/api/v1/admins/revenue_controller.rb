# frozen_string_literal: true

class Api::V1::Admins::RevenueController < Api::V1::BaseController
  def index
    total_revenue = RevenueRecord.sum(:amount)

    this_month_start = Time.current.beginning_of_month
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end   = this_month_start

    this_month_revenue = RevenueRecord.where(created_at: this_month_start..).sum(:amount)
    last_month_revenue = RevenueRecord.where(created_at: last_month_start...last_month_end).sum(:amount)

    monthly_count = RevenueRecord.where(plan_type: "monthly").count
    yearly_count  = RevenueRecord.where(plan_type: "yearly").count

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
                         this_month_revenue:,
                         last_month_revenue:,
                         monthly_count:,
                         yearly_count:,
                         monthly_chart:,
                         recent_transactions:
                       },
                       status: :ok
                     })
  end
end
