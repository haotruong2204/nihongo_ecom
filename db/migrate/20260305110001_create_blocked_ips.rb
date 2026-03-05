# frozen_string_literal: true

class CreateBlockedIps < ActiveRecord::Migration[8.0]
  def change
    create_table :blocked_ips do |t|
      t.string :ip_address, limit: 45, null: false
      t.string :reason, limit: 500
      t.references :blocked_by, null: true, foreign_key: { to_table: :admins }
      t.datetime :created_at, null: false
    end

    add_index :blocked_ips, :ip_address, unique: true
  end
end
