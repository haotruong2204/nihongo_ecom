# frozen_string_literal: true

class JlptTestResultSerializer
  include JSONAPI::Serializer

  attributes :id, :test_id, :level, :section, :correct_count, :incorrect_count,
             :total_questions, :time_used, :time_limit, :passed, :sections,
             :taken_at, :created_at
end
