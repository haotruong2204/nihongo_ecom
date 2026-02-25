# frozen_string_literal: true

class AddDisplayNameToFeedbacks < ActiveRecord::Migration[8.0]
  def change
    add_column :feedbacks, :display_name, :string, null: true
  end
end
