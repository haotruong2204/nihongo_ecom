# frozen_string_literal: true

class AddPageViewsCountToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :page_views_count, :integer, default: 0, null: false

    User.reset_column_information
    User.find_each do |user|
      User.reset_counters(user.id, :page_views)
    end
  end

  def down
    remove_column :users, :page_views_count
  end
end
