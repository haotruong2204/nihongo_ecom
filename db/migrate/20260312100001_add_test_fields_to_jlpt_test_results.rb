# frozen_string_literal: true

class AddTestFieldsToJlptTestResults < ActiveRecord::Migration[8.0]
  def change
    add_column :jlpt_test_results, :test_id, :string, limit: 50
    add_column :jlpt_test_results, :section, :string, limit: 30
    add_index :jlpt_test_results, :test_id
  end
end
