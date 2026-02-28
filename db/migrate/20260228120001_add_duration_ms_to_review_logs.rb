# frozen_string_literal: true

class AddDurationMsToReviewLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :review_logs, :duration_ms, :integer, unsigned: true
  end
end
