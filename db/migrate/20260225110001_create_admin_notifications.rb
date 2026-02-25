# frozen_string_literal: true

class CreateAdminNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_notifications do |t|
      t.string :title, null: false
      t.text :body
      t.string :link
      t.string :notification_type, null: false, default: "feedback"
      t.boolean :read, null: false, default: false
      t.timestamps
    end

    add_index :admin_notifications, :read
    add_index :admin_notifications, :created_at
  end
end
