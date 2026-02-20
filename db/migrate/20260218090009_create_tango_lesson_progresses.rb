# frozen_string_literal: true

class CreateTangoLessonProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :tango_lesson_progresses do |t|
      t.bigint :user_id, null: false
      t.string :book_id, limit: 50, null: false
      t.string :lesson_id, limit: 100, null: false
      t.boolean :completed, null: false, default: false
      t.integer :known_count, null: false, default: 0, unsigned: true
      t.integer :total_count, null: false, default: 0, unsigned: true
      t.datetime :last_studied_at

      t.timestamps
    end

    add_index :tango_lesson_progresses, %i[user_id book_id lesson_id], unique: true,
              name: "idx_tango_progress_unique"
    add_index :tango_lesson_progresses, %i[user_id book_id],
              name: "idx_tango_progress_user_book"
  end
end
