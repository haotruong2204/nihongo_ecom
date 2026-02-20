# frozen_string_literal: true

class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.bigint :user_id
      t.string :name, null: false
      t.string :phone, limit: 50, null: false
      t.string :level, limit: 50
      t.string :email
      t.string :source, limit: 100, null: false, default: "khoa-hoc"

      t.timestamps
    end
  end
end
