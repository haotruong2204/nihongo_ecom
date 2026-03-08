# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :uid, :email, :display_name, :photo_url, :provider, :is_premium, :premium_until, :is_banned,
             :banned_reason, :last_login_at, :created_at, :srs_cards_count, :review_logs_count, :page_views_count,
             :vocab_sets_count, :tango_lesson_progresses_count
end
