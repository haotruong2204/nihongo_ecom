# frozen_string_literal: true

class CustomRoadmapSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :kanji_list, :kanji_per_day, :created_at, :updated_at

  attribute :total_days do |object|
    object.total_days
  end

  attribute :kanji_count do |object|
    object.kanji_list&.length || 0
  end
end
