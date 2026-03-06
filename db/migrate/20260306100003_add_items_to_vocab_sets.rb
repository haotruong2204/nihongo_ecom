# frozen_string_literal: true

class AddItemsToVocabSets < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:vocab_sets, :items)
      add_column :vocab_sets, :items, :json
    end
  end
end
