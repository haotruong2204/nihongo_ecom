# frozen_string_literal: true

class CreateChatRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_rooms do |t|
      t.string     :uid, null: false
      t.references :user, foreign_key: true
      t.string     :status, default: "open"
      t.datetime   :last_admin_reply_at
      t.datetime   :last_user_message_at
      t.datetime   :last_opened_at
      t.text       :admin_note
      t.timestamps
    end

    add_index :chat_rooms, :uid, unique: true
    add_index :chat_rooms, :status
  end
end
