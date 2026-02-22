# frozen_string_literal: true

class Api::V1::Users::DashboardController < Api::V1::UserBaseController
  def me
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserSerializer.new(current_user).serializable_hash,
      status: :ok
                     })
  end
end
