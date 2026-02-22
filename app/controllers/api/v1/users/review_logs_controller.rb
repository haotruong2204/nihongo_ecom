# frozen_string_literal: true

class Api::V1::Users::ReviewLogsController < Api::V1::UserBaseController
  before_action :set_review_log, only: [:show]

  def index
    q = current_user.review_logs.ransack(params[:q])
    pagy, review_logs = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: ReviewLogSerializer.new(review_logs).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: ReviewLogSerializer.new(@review_log).serializable_hash,
      status: :ok
                     })
  end

  def create
    review_log = current_user.review_logs.build(review_log_params)

    if review_log.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: ReviewLogSerializer.new(review_log).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(review_log)
    end
  end

  private

  def set_review_log
    @review_log = current_user.review_logs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def review_log_params
    params.require(:review_log).permit(:kanji, :rating, :interval_before, :interval_after, :reviewed_at)
  end
end
