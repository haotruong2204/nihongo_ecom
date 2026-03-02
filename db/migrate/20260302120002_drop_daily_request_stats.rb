# frozen_string_literal: true

class DropDailyRequestStats < ActiveRecord::Migration[8.0]
  def change
    drop_table :daily_request_stats do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.integer :total_requests, default: 0, null: false
      t.json :endpoint_stats
      t.boolean :flagged, default: false, null: false
      t.string :flag_reason, limit: 200
      t.timestamps
    end
  end
end
