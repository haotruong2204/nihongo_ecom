# frozen_string_literal: true

class CreatePushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :endpoint, null: false
      t.string :endpoint_digest, null: false, limit: 64  # SHA256 hex của endpoint để index unique
      t.string :p256dh_key, null: false
      t.string :auth_key, null: false

      t.timestamps
    end

    add_index :push_subscriptions, :endpoint_digest, unique: true
  end
end
