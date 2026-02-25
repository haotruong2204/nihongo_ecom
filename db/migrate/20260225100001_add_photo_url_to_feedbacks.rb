# frozen_string_literal: true

class AddPhotoUrlToFeedbacks < ActiveRecord::Migration[8.0]
  def change
    add_column :feedbacks, :photo_url, :string, null: true
  end
end
