# frozen_string_literal: true

namespace :cleanup do
  desc "For free users exceeding limits: delete kanji cards > 50 and vocab items > 100, plus corresponding review logs"
  task enforce_free_limits: :environment do
    KANJI_LIMIT = 50
    VOCAB_LIMIT  = 100

    free_users = User.where(is_premium: false)
                     .or(User.where(is_premium: true)
                              .where.not(premium_until: nil)
                              .where("premium_until <= ?", Time.current))

    puts "Found #{free_users.count} free users. Scanning..."

    total_srs_deleted     = 0
    total_review_deleted  = 0
    total_vocab_deleted   = 0
    users_affected        = 0

    free_users.find_each do |user|
      user_affected = false

      # --- Kanji SRS cards ---
      card_ids = SrsCard.where(user_id: user.id).order(created_at: :asc).ids
      if card_ids.size > KANJI_LIMIT
        to_delete = card_ids[KANJI_LIMIT..]
        deleted_kanjis = SrsCard.where(id: to_delete).pluck(:kanji)

        SrsCard.where(id: to_delete).delete_all
        deleted_reviews = ReviewLog.where(user_id: user.id, kanji: deleted_kanjis).delete_all

        total_srs_deleted    += to_delete.size
        total_review_deleted += deleted_reviews
        user_affected = true

        puts "  [#{user.email}] Removed #{to_delete.size} kanji cards, #{deleted_reviews} review logs"
      end

      # --- Custom vocab items ---
      vocab_ids = CustomVocabItem.where(user_id: user.id).order(created_at: :asc).ids
      if vocab_ids.size > VOCAB_LIMIT
        to_delete = vocab_ids[VOCAB_LIMIT..]
        CustomVocabItem.where(id: to_delete).delete_all

        total_vocab_deleted += to_delete.size
        user_affected = true

        puts "  [#{user.email}] Removed #{to_delete.size} vocab items"
      end

      users_affected += 1 if user_affected
    end

    puts "\nDone:"
    puts "  Users affected:       #{users_affected}"
    puts "  Kanji cards deleted:  #{total_srs_deleted}"
    puts "  Review logs deleted:  #{total_review_deleted}"
    puts "  Vocab items deleted:  #{total_vocab_deleted}"
  end
end
