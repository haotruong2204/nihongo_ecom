# frozen_string_literal: true

class ExpirePremiumJob < ApplicationJob
  queue_as :default

  def perform
    expired = User.where(is_premium: true)
                  .where.not(premium_until: nil)
                  .where("premium_until <= ?", Time.current)
                  .update_all(is_premium: false)

    Rails.logger.info("[ExpirePremiumJob] Expired #{expired} premium account(s)")
  end
end
