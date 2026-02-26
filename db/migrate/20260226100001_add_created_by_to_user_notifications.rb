# frozen_string_literal: true

class AddCreatedByToUserNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :user_notifications, :created_by, :string, default: "system", null: false
  end
end
