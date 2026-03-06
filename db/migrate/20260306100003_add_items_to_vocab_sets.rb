# frozen_string_literal: true

class AddItemsToVocabSets < ActiveRecord::Migration[8.0]
  def change
    add_column :vocab_sets, :items, :json
  end
end
