# frozen_string_literal: true

class AddChatBannedToChatRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_rooms, :chat_banned, :boolean, null: false, default: false
    add_column :chat_rooms, :chat_ban_reason, :string, limit: 500
  end
end
