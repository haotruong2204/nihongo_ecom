# frozen_string_literal: true

class Api::V1::Users::RoadmapDayProgressesController < Api::V1::UserBaseController
  before_action :set_roadmap_day_progress, only: [:show, :update, :destroy]

  def index
    q = current_user.roadmap_day_progresses.ransack(params[:q])
    pagy, progresses = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: RoadmapDayProgressSerializer.new(progresses).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: RoadmapDayProgressSerializer.new(@roadmap_day_progress).serializable_hash,
      status: :ok
                     })
  end

  def create
    progress = current_user.roadmap_day_progresses.build(roadmap_day_progress_params)

    if progress.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: RoadmapDayProgressSerializer.new(progress).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(progress)
    end
  end

  def update
    if @roadmap_day_progress.update(roadmap_day_progress_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: RoadmapDayProgressSerializer.new(@roadmap_day_progress).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@roadmap_day_progress)
    end
  end

  def destroy
    @roadmap_day_progress.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_roadmap_day_progress
    @roadmap_day_progress = current_user.roadmap_day_progresses.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def roadmap_day_progress_params
    params.require(:roadmap_day_progress).permit(:day, :completed_at, kanji_learned: [])
  end
end
