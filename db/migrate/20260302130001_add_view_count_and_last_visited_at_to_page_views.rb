# frozen_string_literal: true

class AddViewCountAndLastVisitedAtToPageViews < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:page_views, :view_count)
      add_column :page_views, :view_count, :integer, null: false, default: 1
    end

    if column_exists?(:page_views, :visited_at) && !column_exists?(:page_views, :last_visited_at)
      rename_column :page_views, :visited_at, :last_visited_at
    end

    remove_index :page_views, name: "index_page_views_on_user_id_and_visited_at", if_exists: true
    remove_index :page_views, name: "index_page_views_on_visited_at", if_exists: true

    add_index :page_views, [:user_id, :url], unique: true, if_not_exists: true
    add_index :page_views, :last_visited_at, if_not_exists: true
  end

  def down
    remove_index :page_views, [:user_id, :url], if_exists: true
    remove_index :page_views, :last_visited_at, if_exists: true

    if column_exists?(:page_views, :last_visited_at)
      rename_column :page_views, :last_visited_at, :visited_at
      add_index :page_views, [:user_id, :visited_at]
      add_index :page_views, :visited_at
    end

    remove_column :page_views, :view_count, if_exists: true
  end
end
