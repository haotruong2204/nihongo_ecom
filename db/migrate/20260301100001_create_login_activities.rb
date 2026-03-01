# frozen_string_literal: true

class CreateLoginActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :login_activities do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :ip_address, limit: 45
      t.string :user_agent, limit: 500
      t.string :device_info, limit: 200
      t.boolean :session_conflict, default: false, null: false
      t.datetime :created_at, null: false
    end

    add_index :login_activities, [:user_id, :created_at]
    add_index :login_activities, [:user_id, :session_conflict]
  end
end
