# frozen_string_literal: true

class AddThreadingAndContextToFeedbacks < ActiveRecord::Migration[8.0]
  def change
    add_column :feedbacks, :parent_id, :bigint, null: true
    add_column :feedbacks, :context_type, :string, null: true
    add_column :feedbacks, :context_id, :string, null: true
    add_column :feedbacks, :context_label, :string, null: true

    add_index :feedbacks, :parent_id
    add_index :feedbacks, [:context_type, :context_id]

    add_foreign_key :feedbacks, :feedbacks, column: :parent_id, on_delete: :cascade
  end
end
