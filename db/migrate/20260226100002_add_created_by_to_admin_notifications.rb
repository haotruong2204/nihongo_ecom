# frozen_string_literal: true

class AddCreatedByToAdminNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :admin_notifications, :created_by, :string, default: "system", null: false
  end
end
