# frozen_string_literal: true

class Api::V1::Admins::UserSrsCardsController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user
  before_action :set_card, only: [:destroy, :reset]

  STATUS_MAP = {
    "new" => :new_card,
    "learning" => :learning,
    "review" => :review,
    "relearning" => :relearning
  }.freeze

  def index
    scope = filtered_scope
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

  def destroy
    @card.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  def reset
    @card.update!(
      state: :new_card,
      ease: 2.5,
      interval: 0,
      due_date: Time.current,
      reviews_count: 0,
      lapses_count: 0,
      last_review_at: nil
    )
    response_success({
                       code: 200,
      message: I18n.t("api.common.update_success"),
      resource: SrsCardSerializer.new(@card).serializable_hash,
      status: :ok
                     })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def set_card
    @card = @user.srs_cards.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def filtered_scope
    scope = @user.srs_cards
    status = params[:status].to_s

    if status == "overdue"
      scope.where(due_date: ..Time.current)
    elsif STATUS_MAP.key?(status)
      scope.where(state: STATUS_MAP[status])
    else
      scope
    end
  end

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
