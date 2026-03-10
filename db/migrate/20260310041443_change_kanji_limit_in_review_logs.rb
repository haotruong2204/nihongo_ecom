# frozen_string_literal: true

class ChangeKanjiLimitInReviewLogs < ActiveRecord::Migration[8.0]
  def change
    change_column :review_logs, :kanji, :string, limit: 50, null: false
  end
end
