# frozen_string_literal: true

class CreateCustomRoadmapDayProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_roadmap_day_progresses do |t|
      t.bigint :user_id, null: false
      t.bigint :custom_roadmap_id, null: false
      t.integer :day, null: false, unsigned: true
      t.json :kanji_learned, null: false
      t.datetime :completed_at, null: false

      t.timestamps
    end

    add_index :custom_roadmap_day_progresses, [:user_id, :custom_roadmap_id, :day], unique: true,
              name: "index_custom_roadmap_day_progresses_on_user_roadmap_day"
    add_index :custom_roadmap_day_progresses, :custom_roadmap_id
  end
end
