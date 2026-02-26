# frozen_string_literal: true

class Api::V1::Admins::FeedbacksController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_feedback, only: [:show, :update, :destroy]

  def index
    q = Feedback.roots.ransack(params[:q])
    pagy, feedbacks = pagy(q.result.includes(:user).order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: FeedbackSerializer.new(feedbacks, include: [:user]).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: FeedbackSerializer.new(@feedback, include: [:user, :replies]).serializable_hash,
      status: :ok
                     })
  end

  def update
    feedback_params[:admin_reply].present? && feedback_params[:admin_reply] != @feedback.admin_reply
    was_hidden = !@feedback.display

    if @feedback.update(feedback_params)
      if was_hidden && @feedback.display
        UserNotification.notify_feedback_approved(@feedback)
        UserNotification.notify_user_replied(@feedback.parent, @feedback) if @feedback.parent_id.present?
      end
      @feedback.update_column(:replied_at, Time.current) if @feedback.admin_reply.present? && @feedback.replied_at.nil?

      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: FeedbackSerializer.new(@feedback.reload, include: [:user, :replies]).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@feedback)
    end
  end

  def destroy
    @feedback.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def feedback_params
    params.require(:feedback).permit(:status, :admin_reply, :display)
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
