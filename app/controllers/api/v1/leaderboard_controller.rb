# frozen_string_literal: true

class Api::V1::LeaderboardController < ApplicationController
  include CommonResponse
  include ErrorCode

  respond_to :json

  def index
    cached = REDIS.get(CacheLeaderboardJob::CACHE_KEY)

    users = if cached
              JSON.parse(cached)
            else
              CacheLeaderboardJob.perform_now
              JSON.parse(REDIS.get(CacheLeaderboardJob::CACHE_KEY) || "[]")
            end

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      users: users,
      status: :ok
    })
  end
end
