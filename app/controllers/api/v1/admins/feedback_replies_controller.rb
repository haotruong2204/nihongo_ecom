# frozen_string_literal: true

class Api::V1::Admins::FeedbackRepliesController < Api::V1::BaseController
  before_action :set_feedback

  def create
    reply = @feedback.replies.build(
      text: reply_params[:text],
      email: "admin",
      user_id: nil,
      context_type: @feedback.context_type,
      context_id: @feedback.context_id,
      context_label: @feedback.context_label
    )

    if reply.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: FeedbackSerializer.new(@feedback.reload, include: [:user, :replies]).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(reply)
    end
  end

  private

  def set_feedback
    @feedback = Feedback.roots.find(params[:feedback_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def reply_params
    params.require(:reply).permit(:text)
  end
end
