# frozen_string_literal: true

class Api::V1::PublicFeedbacksController < ApplicationController
  include Pagy::Backend
  include CommonResponse
  include ErrorCode

  respond_to :json

  def index
    q = Feedback.displayed.roots.ransack(params[:q])
    pagy, feedbacks = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: FeedbackSerializer.new(feedbacks, include: [:replies]).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  private

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
