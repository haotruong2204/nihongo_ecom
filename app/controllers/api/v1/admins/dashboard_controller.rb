# frozen_string_literal: true

class Api::V1::Admins::DashboardController < Api::V1::BaseController
  def me
    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: AdminSerializer.new(current_admin).serializable_hash,
                       status: :ok
                     })
  end
end
