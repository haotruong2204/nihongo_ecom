# frozen_string_literal: true

class Api::V1::Users::NotificationsController < Api::V1::UserBaseController
  def index
    notifications = current_user.user_notifications.recent
    notifications = notifications.unread if params[:unread] == "true"
    pagy, records = pagy(notifications, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserNotificationSerializer.new(records).serializable_hash,
      pagy: pagy_metadata(pagy),
      unread_count: current_user.user_notifications.unread.count,
      status: :ok
                     })
  end

  def mark_read
    if params[:id] == "all"
      current_user.user_notifications.unread.update_all(read: true)
    else
      current_user.user_notifications.find(params[:id]).update!(read: true)
    end

    response_success({ code: 200, message: I18n.t("api.common.update_success"), status: :ok })
  end
end
