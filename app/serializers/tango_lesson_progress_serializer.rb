# frozen_string_literal: true

class TangoLessonProgressSerializer
  include JSONAPI::Serializer

  attributes :id, :book_id, :lesson_id, :completed, :known_count, :total_count,
             :last_studied_at, :created_at, :updated_at
end
