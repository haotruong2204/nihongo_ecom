# frozen_string_literal: true

class Api::V1::Users::CustomRoadmapDayProgressesController < Api::V1::UserBaseController
  before_action :set_custom_roadmap

  def index
    progresses = current_user.custom_roadmap_day_progresses
                             .where(custom_roadmap_id: @custom_roadmap.id)
                             .ordered

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: CustomRoadmapDayProgressSerializer.new(progresses).serializable_hash,
      status: :ok
    })
  end

  def create
    progress = current_user.custom_roadmap_day_progresses.find_or_initialize_by(
      custom_roadmap_id: @custom_roadmap.id,
      day: day_progress_params[:day]
    )

    progress.assign_attributes(
      kanji_learned: day_progress_params[:kanji_learned],
      completed_at: day_progress_params[:completed_at] || Time.current
    )

    if progress.save
      response_success({
        code: 200,
        message: I18n.t("api.common.create_success"),
        resource: CustomRoadmapDayProgressSerializer.new(progress).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(progress)
    end
  end

  private

  def set_custom_roadmap
    @custom_roadmap = current_user.custom_roadmaps.find(params[:custom_roadmap_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def day_progress_params
    params.require(:custom_roadmap_day_progress).permit(:day, :completed_at, kanji_learned: [])
  end
end
