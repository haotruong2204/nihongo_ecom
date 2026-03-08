class AddSlotsLockedToUsers < ActiveRecord::Migration[7.2]
  KANJI_LIMIT = 50
  VOCAB_LIMIT = 100

  def change
    add_column :users, :kanji_slots_locked, :boolean, default: false, null: false
    add_column :users, :vocab_slots_locked, :boolean, default: false, null: false

    # Backfill: lock free users who already exceeded limits
    reversible do |dir|
      dir.up do
        User.where(is_premium: false).find_each do |user|
          kanji_count = user.srs_cards.where(reading: [nil, ""]).count
          vocab_count = user.srs_cards.where.not(reading: [nil, ""]).count

          user.update_columns(
            kanji_slots_locked: kanji_count >= KANJI_LIMIT,
            vocab_slots_locked: vocab_count >= VOCAB_LIMIT
          )
        end
      end
    end
  end
end
