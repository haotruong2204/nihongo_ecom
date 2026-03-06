# frozen_string_literal: true

class CreateVocabSets < ActiveRecord::Migration[8.0]
  def change
    create_table :vocab_sets do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false, limit: 100
      t.json :items
      t.integer :position, null: false, default: 0, unsigned: true

      t.timestamps
    end

    add_index :vocab_sets, :user_id
    add_foreign_key :vocab_sets, :users
  end
end
