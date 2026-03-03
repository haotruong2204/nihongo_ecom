# frozen_string_literal: true

class AddCounterCacheToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :srs_cards_count, :integer, default: 0, null: false
    add_column :users, :review_logs_count, :integer, default: 0, null: false

    # Populate existing counts
    User.reset_column_information
    User.find_each do |user|
      User.reset_counters(user.id, :srs_cards, :review_logs)
    end
  end

  def down
    remove_column :users, :srs_cards_count
    remove_column :users, :review_logs_count
  end
end
