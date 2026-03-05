# frozen_string_literal: true

class Api::V1::Admins::DevtoolsLogsController < Api::V1::BaseController
  include Pagy::Backend

  def index
    q = DevtoolsLog.ransack(params[:q])
    pagy, logs = pagy(q.result.recent, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: DevtoolsLogSerializer.new(logs).serializable_hash,
                       pagy: pagy_metadata(pagy),
                       status: :ok
                     })
  end

  private

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
