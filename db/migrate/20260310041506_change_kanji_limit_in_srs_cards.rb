# frozen_string_literal: true

class ChangeKanjiLimitInSrsCards < ActiveRecord::Migration[8.0]
  def change
    change_column :srs_cards, :kanji, :string, limit: 50, null: false
  end
end
