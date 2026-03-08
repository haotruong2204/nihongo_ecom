# frozen_string_literal: true

class CustomRoadmapDayProgressSerializer
  include JSONAPI::Serializer

  attributes :id, :custom_roadmap_id, :day, :kanji_learned, :completed_at, :created_at, :updated_at
end
