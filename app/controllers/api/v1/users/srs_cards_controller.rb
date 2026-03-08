# frozen_string_literal: true

class Api::V1::Users::SrsCardsController < Api::V1::UserBaseController
  before_action :set_srs_card, only: [:show, :update, :destroy]
  before_action :require_srs_card, only: [:show, :update]
  before_action :sync_slots_locked_on_expiry

  def index
    scope = accessible_srs_cards
    q = scope.ransack(params[:q])
    pagy, srs_cards = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: SrsCardSerializer.new(srs_cards).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: SrsCardSerializer.new(@srs_card).serializable_hash,
      status: :ok
                     })
  end

  FREE_KANJI_LIMIT = 50
  FREE_VOCAB_LIMIT = 100

  # Enforce slot-lock flags whenever premium has expired and user is over free limits.
  # Runs lazily on each request so no background job is needed.
  def sync_slots_locked_on_expiry
    return if current_user.premium?

    unless current_user.vocab_slots_locked?
      vocab_count = current_user.srs_cards.where.not(reading: [nil, ""]).count
      current_user.update_column(:vocab_slots_locked, true) if vocab_count > FREE_VOCAB_LIMIT
    end

    unless current_user.kanji_slots_locked?
      kanji_count = current_user.srs_cards.where(reading: [nil, ""]).count
      current_user.update_column(:kanji_slots_locked, true) if kanji_count > FREE_KANJI_LIMIT
    end
  end

  def create
    srs_card = current_user.srs_cards.find_or_initialize_by(kanji: srs_card_params[:kanji])

    # Enforce free-tier limits on new cards only
    if srs_card.new_record? && !current_user.premium?
      is_vocab = srs_card_params[:reading].present?
      if is_vocab
        unless current_user.vocab_slots_locked?
          vocab_count = current_user.srs_cards.where.not(reading: [nil, ""]).count
          current_user.update_column(:vocab_slots_locked, true) if vocab_count >= FREE_VOCAB_LIMIT
        end
        if current_user.vocab_slots_locked?
          return render json: { message: "FREE_LIMIT_REACHED", detail: "Giới hạn #{FREE_VOCAB_LIMIT} từ vựng cho tài khoản miễn phí" }, status: :forbidden
        end
      else
        unless current_user.kanji_slots_locked?
          kanji_count = current_user.srs_cards.where(reading: [nil, ""]).count
          current_user.update_column(:kanji_slots_locked, true) if kanji_count >= FREE_KANJI_LIMIT
        end
        if current_user.kanji_slots_locked?
          return render json: { message: "FREE_LIMIT_REACHED", detail: "Giới hạn #{FREE_KANJI_LIMIT} kanji cho tài khoản miễn phí" }, status: :forbidden
        end
      end
    end

    if srs_card.new_record?
      srs_card.assign_attributes(srs_card_params)
    else
      # Update vocab metadata for existing cards
      srs_card.assign_attributes(srs_card_params.slice(:reading, :meaning, :hanviet, :accents).compact_blank)
    end

    if srs_card.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: SrsCardSerializer.new(srs_card).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(srs_card)
    end
  end

  def update
    if @srs_card.update(srs_card_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: SrsCardSerializer.new(@srs_card).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@srs_card)
    end
  end

  def destroy
    @srs_card&.destroy
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  # For premium users: all cards.
  # For free users: oldest FREE_KANJI_LIMIT kanji + oldest FREE_VOCAB_LIMIT vocab.
  # "Oldest first" so data accumulated before premium expires is the locked portion,
  # not the data the user had as a free user.
  def accessible_srs_cards
    return current_user.srs_cards if current_user.premium?

    kanji_ids = current_user.srs_cards
                            .where(reading: [nil, ""])
                            .order(:created_at)
                            .limit(FREE_KANJI_LIMIT)
                            .ids
    vocab_ids = current_user.srs_cards
                            .where.not(reading: [nil, ""])
                            .order(:created_at)
                            .limit(FREE_VOCAB_LIMIT)
                            .ids

    current_user.srs_cards.where(id: kanji_ids + vocab_ids)
  end

  def set_srs_card
    @srs_card = accessible_srs_cards.find_by(id: params[:id])
  end

  def require_srs_card
    not_found unless @srs_card
  end

  def srs_card_params
    params.require(:srs_card).permit(:kanji, :state, :ease, :interval, :due_date,
                                     :reviews_count, :lapses_count, :last_review_at,
                                     :reading, :meaning, :hanviet, accents: [])
  end
end
