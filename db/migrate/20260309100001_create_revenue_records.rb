# frozen_string_literal: true

class CreateRevenueRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :revenue_records do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :plan_type, null: false, default: "monthly"
      t.datetime :premium_until

      t.timestamps
    end

    add_index :revenue_records, :created_at
    add_index :revenue_records, :plan_type
  end
end
