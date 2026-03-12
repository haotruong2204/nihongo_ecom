# frozen_string_literal: true

class ExpirePremiumJob < ApplicationJob
  queue_as :default

  FREE_KANJI_LIMIT = 50
  FREE_VOCAB_LIMIT = 100

  def perform
    expired_users = User.where(is_premium: true)
                        .where.not(premium_until: nil)
                        .where("premium_until <= ?", Time.current)
                        .to_a  # load before update_all changes the scope

    User.where(id: expired_users.map(&:id)).update_all(is_premium: false)
    Rails.logger.info("[ExpirePremiumJob] Expired #{expired_users.size} premium account(s)")

    expired_users.each do |user|
      enforce_free_limits(user)
    end
  end

  private

  def enforce_free_limits(user)
    # Kanji cards: reading is nil or blank — keep newest FREE_KANJI_LIMIT
    kanji_ids = user.srs_cards.where(reading: [nil, ""])
                               .order(created_at: :desc)
                               .ids
    if kanji_ids.size > FREE_KANJI_LIMIT
      to_delete = kanji_ids[FREE_KANJI_LIMIT..]
      deleted_kanjis = SrsCard.where(id: to_delete).pluck(:kanji)
      SrsCard.where(id: to_delete).delete_all
      ReviewLog.where(user_id: user.id, kanji: deleted_kanjis).delete_all
      Rails.logger.info("[ExpirePremiumJob] user##{user.id}: removed #{to_delete.size} kanji cards")
    end

    # Vocab cards: reading is present — keep newest FREE_VOCAB_LIMIT
    vocab_ids = user.srs_cards.where.not(reading: [nil, ""])
                               .order(created_at: :desc)
                               .ids
    if vocab_ids.size > FREE_VOCAB_LIMIT
      to_delete = vocab_ids[FREE_VOCAB_LIMIT..]
      deleted_kanjis = SrsCard.where(id: to_delete).pluck(:kanji)
      SrsCard.where(id: to_delete).delete_all
      ReviewLog.where(user_id: user.id, kanji: deleted_kanjis).delete_all
      Rails.logger.info("[ExpirePremiumJob] user##{user.id}: removed #{to_delete.size} vocab cards")
    end

    user.update_columns(
      kanji_slots_locked: user.srs_cards.where(reading: [nil, ""]).count >= FREE_KANJI_LIMIT,
      vocab_slots_locked: user.srs_cards.where.not(reading: [nil, ""]).count >= FREE_VOCAB_LIMIT
    )

    # Delete all active-learning vocab sets and custom vocab items
    deleted_sets = user.vocab_sets.delete_all
    deleted_items = user.custom_vocab_items.delete_all
    Rails.logger.info("[ExpirePremiumJob] user##{user.id}: removed #{deleted_sets} vocab set(s), #{deleted_items} custom vocab item(s)")
  end
end
