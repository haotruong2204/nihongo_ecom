# frozen_string_literal: true

class Api::V1::Admins::UserLoginActivitiesController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user
  before_action :set_login_activity, only: [:destroy]

  def index
    q = @user.login_activities.ransack(params[:q])
    pagy, activities = pagy(q.result.recent, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: LoginActivitySerializer.new(activities).serializable_hash,
                       pagy: pagy_metadata(pagy),
                       status: :ok
                     })
  end

  def destroy
    @login_activity.destroy!
    response_success({ code: 200, message: I18n.t("api.common.success"), status: :ok })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def set_login_activity
    @login_activity = @user.login_activities.find(params[:id])
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
