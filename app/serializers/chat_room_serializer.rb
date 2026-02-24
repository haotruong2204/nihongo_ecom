# frozen_string_literal: true

class ChatRoomSerializer
  include JSONAPI::Serializer

  attributes :id, :uid, :status, :chat_banned, :chat_ban_reason,
             :last_admin_reply_at, :last_user_message_at,
             :last_opened_at, :admin_note, :created_at, :updated_at

  attribute :user do |room|
    if room.user
      {
        id: room.user.id,
        uid: room.user.uid,
        email: room.user.email,
        display_name: room.user.display_name,
        photo_url: room.user.photo_url,
        is_premium: room.user.premium?,
        premium_until: room.user.premium_until,
        is_banned: room.user.banned?,
        banned_reason: room.user.banned_reason,
        last_login_at: room.user.last_login_at,
        created_at: room.user.created_at
      }
    end
  end
end
