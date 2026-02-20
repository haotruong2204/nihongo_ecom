# frozen_string_literal: true

class CreateJlptTestResults < ActiveRecord::Migration[8.0]
  def change
    create_table :jlpt_test_results do |t|
      t.bigint :user_id, null: false
      t.string :level, limit: 10, null: false
      t.integer :correct_count, null: false, unsigned: true
      t.integer :incorrect_count, null: false, unsigned: true
      t.integer :total_questions, null: false, default: 35, unsigned: true
      t.integer :time_used, null: false, unsigned: true
      t.integer :time_limit, null: false, default: 1800, unsigned: true
      t.boolean :passed, null: false
      t.json :sections, null: false
      t.datetime :taken_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :jlpt_test_results, %i[user_id level]
    add_index :jlpt_test_results, %i[user_id taken_at]
  end
end
