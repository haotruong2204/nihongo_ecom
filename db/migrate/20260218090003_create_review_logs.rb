# frozen_string_literal: true

class CreateReviewLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :review_logs do |t|
      t.bigint :user_id, null: false
      t.string :kanji, limit: 10, null: false
      t.integer :rating, limit: 1, null: false
      t.integer :interval_before, null: false, default: 0, unsigned: true
      t.integer :interval_after, null: false, default: 0, unsigned: true
      t.datetime :reviewed_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :review_logs, %i[user_id reviewed_at]
    add_index :review_logs, %i[user_id kanji]
  end
end
