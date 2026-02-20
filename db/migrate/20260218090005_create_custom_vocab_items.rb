# frozen_string_literal: true

class CreateCustomVocabItems < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_vocab_items do |t|
      t.bigint :user_id, null: false
      t.string :word, null: false
      t.string :reading, null: false
      t.string :hanviet, null: false, default: ""
      t.string :meaning, limit: 500, null: false
      t.integer :position, null: false, default: 0, unsigned: true

      t.timestamps
    end

    add_index :custom_vocab_items, %i[user_id word], unique: true
    add_index :custom_vocab_items, %i[user_id position]
  end
end
