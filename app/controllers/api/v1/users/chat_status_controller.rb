# frozen_string_literal: true

class Api::V1::Users::ChatStatusController < Api::V1::UserBaseController
  RATE_LIMIT_MAX = 5
  RATE_LIMIT_PERIOD = 60 # seconds

  # GET /api/v1/users/chat_status
  def show
    count = redis_count(current_user.uid)
    remaining = [RATE_LIMIT_MAX - count, 0].max

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: {
        rate_limit: {
          max: RATE_LIMIT_MAX,
          period: RATE_LIMIT_PERIOD,
          remaining: remaining
        }
      }
                     })
  end

  # POST /api/v1/users/chat_messages
  def record_message
    count = redis_increment(current_user.uid)
    remaining = [RATE_LIMIT_MAX - count, 0].max

    if count > RATE_LIMIT_MAX
      return response_success({
                                code: 200,
        message: "Rate limited",
        resource: { remaining: 0, warning: true, rate_limited: true }
                              })
    end

    ChatRoom.find_by(uid: current_user.uid)&.update(last_user_message_at: Time.current)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: {
        remaining: remaining,
        warning: remaining <= 1
      }
                     })
  end

  private

  def redis_client
    @redis_client ||= Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379")
  end

  def redis_key uid
    "chat_rate:#{uid}"
  end

  def redis_count uid
    redis_client.get(redis_key(uid)).to_i
  end

  def redis_increment uid
    key = redis_key(uid)
    count = redis_client.incr(key)
    redis_client.expire(key, RATE_LIMIT_PERIOD) if count == 1
    count
  end
end
