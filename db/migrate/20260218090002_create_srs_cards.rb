# frozen_string_literal: true

class CreateSrsCards < ActiveRecord::Migration[8.0]
  def change
    create_table :srs_cards do |t|
      t.bigint :user_id, null: false
      t.string :kanji, limit: 10, null: false
      t.integer :state, limit: 1, null: false, default: 0
      t.decimal :ease, precision: 4, scale: 2, null: false, default: 2.50
      t.integer :interval, null: false, default: 0, unsigned: true
      t.datetime :due_date, null: false
      t.integer :reviews_count, null: false, default: 0, unsigned: true
      t.integer :lapses_count, null: false, default: 0, unsigned: true
      t.datetime :last_review_at

      t.timestamps
    end

    add_index :srs_cards, %i[user_id kanji], unique: true
    add_index :srs_cards, %i[user_id due_date]
    add_index :srs_cards, %i[user_id state]
    add_index :srs_cards, %i[user_id interval]
  end
end
