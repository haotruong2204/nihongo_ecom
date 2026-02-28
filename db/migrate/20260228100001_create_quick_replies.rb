# frozen_string_literal: true

class CreateQuickReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :quick_replies do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :quick_replies, :position
    add_index :quick_replies, :active
  end
end
