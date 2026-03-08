# frozen_string_literal: true

class CreateCustomRoadmaps < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_roadmaps do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false, limit: 100
      t.json :kanji_list, null: false
      t.integer :kanji_per_day, null: false, default: 10

      t.timestamps
    end

    add_index :custom_roadmaps, :user_id
    add_index :custom_roadmaps, [:user_id, :created_at]
  end
end
