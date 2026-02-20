# frozen_string_literal: true

class CreateUserSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_settings do |t|
      t.bigint :user_id, null: false
      t.string :learn_mode, limit: 20, null: false, default: "kanji"
      t.string :kanji_font, limit: 50, null: false, default: "zen-maru-gothic"
      t.string :primary_color, limit: 50, null: false, default: "205 100% 50%"

      t.timestamps
    end

    add_index :user_settings, :user_id, unique: true
  end
end
