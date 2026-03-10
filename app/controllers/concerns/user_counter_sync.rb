# frozen_string_literal: true

module UserCounterSync
  extend ActiveSupport::Concern

  COUNTER_ASSOCIATIONS = %i[srs_cards review_logs vocab_sets tango_lesson_progresses page_views].freeze

  def sync_user_counters(user)
    User.reset_counters(user.id, *COUNTER_ASSOCIATIONS)
    REDIS.del("user_stats:#{user.id}")
  end
end
