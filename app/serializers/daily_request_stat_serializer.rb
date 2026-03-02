# frozen_string_literal: true

class DailyRequestStatSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :date, :total_requests, :endpoint_stats, :flagged, :flag_reason, :created_at

  belongs_to :user
end
