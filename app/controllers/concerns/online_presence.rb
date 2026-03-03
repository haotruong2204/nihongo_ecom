# frozen_string_literal: true

module OnlinePresence
  extend ActiveSupport::Concern

  def online_users_count
    count = 0
    cursor = "0"

    loop do
      cursor, keys = REDIS.scan(cursor, match: "presence:user:*", count: 100)
      count += keys.size
      break if cursor == "0"
    end

    count
  rescue Redis::BaseError
    0
  end

  def online_user_ids
    ids = []
    cursor = "0"

    loop do
      cursor, keys = REDIS.scan(cursor, match: "presence:user:*", count: 100)
      ids.concat(keys.map { |k| k.split(":").last.to_i })
      break if cursor == "0"
    end

    ids
  rescue Redis::BaseError
    []
  end

  def user_online?(user_id)
    REDIS.exists?("presence:user:#{user_id}")
  rescue Redis::BaseError
    false
  end
end
