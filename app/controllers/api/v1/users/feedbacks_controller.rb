# frozen_string_literal: true

class Api::V1::Users::FeedbacksController < Api::V1::UserBaseController
  before_action :set_feedback, only: [:show]

  def index
    q = current_user.feedbacks.ransack(params[:q])
    pagy, feedbacks = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: FeedbackSerializer.new(feedbacks).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: FeedbackSerializer.new(@feedback).serializable_hash,
      status: :ok
                     })
  end

  def create
    feedback = current_user.feedbacks.build(feedback_params)
    feedback.email = current_user.email

    if feedback.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: FeedbackSerializer.new(feedback).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(feedback)
    end
  end

  private

  def set_feedback
    @feedback = current_user.feedbacks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def feedback_params
    params.require(:feedback).permit(:text, :email)
  end
end
