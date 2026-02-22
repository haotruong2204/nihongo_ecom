# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :display_name, :photo_url, :provider, :is_premium, :premium_until, :is_banned,
             :banned_reason, :last_login_at
end
