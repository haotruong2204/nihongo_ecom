# frozen_string_literal: true

class CreateUserNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :user_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :link
      t.string :notification_type, null: false, default: "feedback"
      t.boolean :read, null: false, default: false
      t.timestamps
    end

    add_index :user_notifications, [:user_id, :read]
  end
end
