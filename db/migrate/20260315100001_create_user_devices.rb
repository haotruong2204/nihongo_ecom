# frozen_string_literal: true

class CreateUserDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :user_devices do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :device_id, null: false
      t.string :device_name, null: false, default: "Unknown"
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    add_index :user_devices, [:user_id, :device_id], unique: true
  end
end
