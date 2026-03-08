# frozen_string_literal: true

class Api::V1::Users::CustomRoadmapsController < Api::V1::UserBaseController
  before_action :set_custom_roadmap, only: [:show, :update, :destroy]

  def index
    roadmaps = current_user.custom_roadmaps.ordered
    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: CustomRoadmapSerializer.new(roadmaps).serializable_hash,
      status: :ok
    })
  end

  def show
    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: CustomRoadmapSerializer.new(@custom_roadmap).serializable_hash,
      status: :ok
    })
  end

  def create
    roadmap = current_user.custom_roadmaps.build(custom_roadmap_params)

    if roadmap.save
      response_success({
        code: 200,
        message: I18n.t("api.common.create_success"),
        resource: CustomRoadmapSerializer.new(roadmap).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(roadmap)
    end
  end

  def update
    if @custom_roadmap.update(custom_roadmap_params)
      response_success({
        code: 200,
        message: I18n.t("api.common.update_success"),
        resource: CustomRoadmapSerializer.new(@custom_roadmap).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(@custom_roadmap)
    end
  end

  def destroy
    @custom_roadmap.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_custom_roadmap
    @custom_roadmap = current_user.custom_roadmaps.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def custom_roadmap_params
    params.require(:custom_roadmap).permit(:name, :kanji_per_day, kanji_list: [])
  end
end
