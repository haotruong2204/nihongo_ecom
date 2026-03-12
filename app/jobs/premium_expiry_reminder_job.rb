# frozen_string_literal: true

class PremiumExpiryReminderJob < ApplicationJob
  queue_as :default

  def perform
    target_date = 2.days.from_now.to_date

    users = User.where(is_premium: true)
                .where.not(premium_until: nil)
                .where(premium_until: target_date.all_day)

    users.each do |user|
      UserMailer.premium_expiry_reminder(user).deliver_later
    end

    Rails.logger.info("[PremiumExpiryReminderJob] Sent reminder to #{users.size} user(s)")
  end
end
