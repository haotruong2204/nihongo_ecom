# frozen_string_literal: true

class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.bigint :user_id
      t.string :email
      t.text :text, null: false
      t.boolean :display, null: false, default: false
      t.integer :status, limit: 1, null: false, default: 0
      t.text :admin_reply
      t.datetime :replied_at

      t.timestamps
    end

    add_index :feedbacks, :user_id
    add_index :feedbacks, :status
    add_index :feedbacks, :created_at
  end
end
