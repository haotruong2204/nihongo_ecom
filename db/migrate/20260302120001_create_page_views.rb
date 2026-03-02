# frozen_string_literal: true

class CreatePageViews < ActiveRecord::Migration[8.0]
  def change
    create_table :page_views do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :url, null: false, limit: 500
      t.integer :view_count, null: false, default: 1
      t.datetime :last_visited_at, null: false
    end

    add_index :page_views, [:user_id, :url], unique: true
  end
end
