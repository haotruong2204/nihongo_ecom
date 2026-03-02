# frozen_string_literal: true

class CreatePageViews < ActiveRecord::Migration[8.0]
  def change
    create_table :page_views do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :url, null: false, limit: 500
      t.datetime :visited_at, null: false
    end

    add_index :page_views, [:user_id, :visited_at]
    add_index :page_views, :visited_at
  end
end
