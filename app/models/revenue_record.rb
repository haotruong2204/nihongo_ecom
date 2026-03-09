# frozen_string_literal: true

class RevenueRecord < ApplicationRecord
  belongs_to :user

  MONTHLY_PRICE = 29_000
  YEARLY_PRICE = 199_000

  # Called after admin upgrades a user to premium
  def self.record_upgrade(user)
    plan_type = plan_type_from_until(user.premium_until)
    amount = plan_type == "yearly" ? YEARLY_PRICE : MONTHLY_PRICE

    create!(
      user: user,
      amount: amount,
      plan_type: plan_type,
      premium_until: user.premium_until
    )
  end

  # reference_time: thời điểm upgrade (dùng cho sync data cũ)
  def self.plan_type_from_until(premium_until, reference_time = Time.current)
    return "monthly" if premium_until.nil?

    days = ((premium_until - reference_time) / 1.day).round
    days >= 300 ? "yearly" : "monthly"
  end
end
