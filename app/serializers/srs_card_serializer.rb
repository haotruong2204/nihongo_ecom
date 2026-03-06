# frozen_string_literal: true

class SrsCardSerializer
  include JSONAPI::Serializer

  attributes :id, :kanji, :state, :ease, :interval, :due_date,
             :reviews_count, :lapses_count, :last_review_at,
             :reading, :meaning, :hanviet, :accents,
             :created_at, :updated_at
end
