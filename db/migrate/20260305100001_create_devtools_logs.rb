# frozen_string_literal: true

class CreateDevtoolsLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :devtools_logs do |t|
      t.references :user, null: true, foreign_key: { on_delete: :cascade }
      t.string :ip_address, limit: 45, null: false
      t.string :user_agent, limit: 500
      t.string :email, limit: 255
      t.integer :open_count, default: 1, null: false
      t.datetime :last_detected_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :devtools_logs, :ip_address
    add_index :devtools_logs, :last_detected_at
  end
end
