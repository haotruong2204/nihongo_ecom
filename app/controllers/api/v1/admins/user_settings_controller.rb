# frozen_string_literal: true

class Api::V1::Admins::UserSettingsController < Api::V1::BaseController
  before_action :set_user

  def show
    setting = @user.user_setting

    if setting
      response_success({
                         code: 200,
        message: I18n.t("api.common.success"),
        resource: UserSettingSerializer.new(setting).serializable_hash,
        status: :ok
                       })
    else
      response_success({ code: 200, message: I18n.t("api.common.success"), resource: nil, status: :ok })
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end
end
