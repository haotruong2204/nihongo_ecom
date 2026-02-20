# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :uid, limit: 128, null: false
      t.string :email, null: false
      t.string :display_name
      t.text :photo_url
      t.string :provider, limit: 50, null: false, default: "google"
      t.boolean :is_premium, null: false, default: false
      t.datetime :premium_until
      t.string :jti, null: false
      t.datetime :last_login_at

      t.timestamps
    end

    add_index :users, :uid, unique: true
    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
  end
end
