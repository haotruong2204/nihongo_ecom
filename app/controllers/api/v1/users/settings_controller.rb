# frozen_string_literal: true

class Api::V1::Users::SettingsController < Api::V1::UserBaseController
  def show
    setting = current_user.user_setting || current_user.build_user_setting

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserSettingSerializer.new(setting).serializable_hash,
      status: :ok
                     })
  end

  def update
    setting = current_user.user_setting || current_user.build_user_setting

    if setting.update(setting_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: UserSettingSerializer.new(setting).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(setting)
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:learn_mode, :kanji_font, :primary_color)
  end
end
