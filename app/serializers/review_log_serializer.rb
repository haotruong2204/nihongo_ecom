# frozen_string_literal: true

class ReviewLogSerializer
  include JSONAPI::Serializer

  attributes :id, :kanji, :rating, :interval_before, :interval_after, :reviewed_at, :created_at
end
