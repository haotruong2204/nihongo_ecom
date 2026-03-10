# frozen_string_literal: true

class Api::V1::Users::SrsResetController < Api::V1::UserBaseController
  DEFAULT_EASE = 2.5

  def create
    card_type = params[:card_type].to_s # "kanji", "vocab", hoặc blank = all

    cards_scope = case card_type
                  when "kanji" then current_user.srs_cards.where(reading: nil)
                  when "vocab" then current_user.srs_cards.where.not(reading: nil)
                  else current_user.srs_cards
                  end

    kanji_keys = cards_scope.pluck(:kanji)

    # Reset state về "new" — giữ nguyên cards, xóa review_logs tương ứng
    cards_scope.update_all(
      state: "new_card",
      ease: DEFAULT_EASE,
      interval: 0,
      due_date: Time.current,
      reviews_count: 0,
      lapses_count: 0,
      last_review_at: nil
    )

    # Xóa review_logs để stats reset sạch
    # KHÔNG touch total_reviews_ever — giữ lại cho leaderboard
    current_user.review_logs.where(kanji: kanji_keys).delete_all if kanji_keys.any?

    # Sync counter cache
    User.reset_counters(current_user.id, :review_logs)

    response_success({ code: 200, message: "Đã đặt lại tiến trình. Bắt đầu ôn lại từ đầu!", status: :ok })
  end
end
