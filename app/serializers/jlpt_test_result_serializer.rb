# frozen_string_literal: true

class JlptTestResultSerializer
  include JSONAPI::Serializer

  attributes :id, :level, :correct_count, :incorrect_count, :total_questions,
             :time_used, :time_limit, :passed, :taken_at, :created_at
end
