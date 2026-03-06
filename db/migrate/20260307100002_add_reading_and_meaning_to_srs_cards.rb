class AddReadingAndMeaningToSrsCards < ActiveRecord::Migration[8.0]
  def change
    add_column :srs_cards, :reading, :string, limit: 200
    add_column :srs_cards, :meaning, :string, limit: 500
    add_column :srs_cards, :hanviet, :string, limit: 200
    add_column :srs_cards, :accents, :json
  end
end
