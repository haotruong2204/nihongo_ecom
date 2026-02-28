# frozen_string_literal: true

class Api::V1::Users::SrsCardsController < Api::V1::UserBaseController
  before_action :set_srs_card, only: [:show, :update, :destroy]
  before_action :require_srs_card, only: [:show, :update]

  def index
    q = current_user.srs_cards.ransack(params[:q])
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

  def create
    srs_card = current_user.srs_cards.find_or_initialize_by(kanji: srs_card_params[:kanji])
    srs_card.assign_attributes(srs_card_params) if srs_card.new_record?

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

  def set_srs_card
    @srs_card = current_user.srs_cards.find_by(id: params[:id])
  end

  def require_srs_card
    not_found unless @srs_card
  end

  def srs_card_params
    params.require(:srs_card).permit(:kanji, :state, :ease, :interval, :due_date,
                                     :reviews_count, :lapses_count, :last_review_at)
  end
end
