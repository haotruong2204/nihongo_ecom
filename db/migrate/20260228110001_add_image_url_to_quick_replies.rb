# frozen_string_literal: true

class AddImageUrlToQuickReplies < ActiveRecord::Migration[8.0]
  def change
    add_column :quick_replies, :image_url, :string
  end
end
