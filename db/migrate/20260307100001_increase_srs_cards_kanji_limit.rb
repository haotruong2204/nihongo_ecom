# frozen_string_literal: true

class IncreaseSrsCardsKanjiLimit < ActiveRecord::Migration[8.0]
  def change
    change_column :srs_cards, :kanji, :string, limit: 100, null: false
  end
end
