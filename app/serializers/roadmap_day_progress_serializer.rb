# frozen_string_literal: true

class RoadmapDayProgressSerializer
  include JSONAPI::Serializer

  attributes :id, :day, :kanji_learned, :completed_at, :created_at, :updated_at
end
