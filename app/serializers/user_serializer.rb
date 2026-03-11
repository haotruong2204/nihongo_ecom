# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :uid, :email, :display_name, :photo_url, :provider, :is_premium, :premium_until, :is_banned,
             :banned_reason, :last_login_at, :created_at, :srs_cards_count, :review_logs_count, :page_views_count,
             :vocab_sets_count, :tango_lesson_progresses_count, :kanji_slots_locked, :vocab_slots_locked

  attribute :kanji_srs_cards_count do |user|
    user.srs_cards.where(reading: [nil, ""]).count
  end

  attribute :vocab_srs_cards_count do |user|
    user.srs_cards.where.not(reading: [nil, ""]).count
  end
end
