# frozen_string_literal: true

class CreateRoadmapDayProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :roadmap_day_progresses do |t|
      t.bigint :user_id, null: false
      t.integer :day, null: false, unsigned: true
      t.json :kanji_learned, null: false
      t.datetime :completed_at, null: false

      t.timestamps
    end

    add_index :roadmap_day_progresses, %i[user_id day], unique: true
    add_index :roadmap_day_progresses, %i[user_id completed_at]
  end
end
