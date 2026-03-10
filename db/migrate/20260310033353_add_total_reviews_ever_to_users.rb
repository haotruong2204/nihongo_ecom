class AddTotalReviewsEverToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :total_reviews_ever, :integer, default: 0, null: false
    # Backfill từ review_logs_count hiện tại
    User.update_all("total_reviews_ever = review_logs_count")
  end
end
