# frozen_string_literal: true

class Api::V1::Admins::UsersController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user, only: [:show, :update, :destroy]

  def index
    q = User.ransack(params[:q])
    q.sorts = "created_at desc" if q.sorts.empty?
    pagy, users = pagy(q.result, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserSerializer.new(users).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    stats = {
      srs_cards_count: @user.srs_cards.count,
      review_logs_count: @user.review_logs.count,
      custom_vocab_items_count: @user.custom_vocab_items.count,
      roadmap_day_progresses_count: @user.roadmap_day_progresses.count,
      tango_lesson_progresses_count: @user.tango_lesson_progresses.count,
      jlpt_test_results_count: @user.jlpt_test_results.count
    }

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserSerializer.new(@user).serializable_hash,
      stats: stats,
      status: :ok
                     })
  end

  def update
    if @user.update(user_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: UserSerializer.new(@user).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@user)
    end
  end

  def destroy
    @user.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def user_params
    params.require(:user).permit(:is_premium, :premium_until, :is_banned, :banned_reason)
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
