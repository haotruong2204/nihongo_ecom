# frozen_string_literal: true

class Api::V1::Admins::UserRoadmapDayProgressesController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user

  def index
    q = @user.roadmap_day_progresses.ransack(params[:q])
    pagy, progresses = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: RoadmapDayProgressSerializer.new(progresses).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    not_found
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
