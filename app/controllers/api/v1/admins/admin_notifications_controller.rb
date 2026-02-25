# frozen_string_literal: true

class Api::V1::Admins::AdminNotificationsController < Api::V1::BaseController
  include Pagy::Backend

  def index
    notifications = AdminNotification.recent
    notifications = notifications.unread if params[:unread] == "true"
    pagy, records = pagy(notifications, limit: params[:per_page] || 20)

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: AdminNotificationSerializer.new(records).serializable_hash,
      pagy: pagy_metadata(pagy),
      unread_count: AdminNotification.unread.count,
      status: :ok
    })
  end

  def mark_read
    if params[:id] == "all"
      AdminNotification.unread.update_all(read: true)
    else
      AdminNotification.find(params[:id]).update!(read: true)
    end

    response_success({ code: 200, message: I18n.t("api.common.update_success"), status: :ok })
  end

  private

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
