# frozen_string_literal: true

class Api::V1::Admins::AdminNotificationsController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_notification, only: [:show, :update, :destroy]

  def index
    q = AdminNotification.ransack(params[:q])
    notifications = q.result.recent
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

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: AdminNotificationSerializer.new(@notification).serializable_hash,
      status: :ok
                     })
  end

  def create
    notification = AdminNotification.new(notification_params.merge(created_by: "admin"))

    if notification.save
      response_success({
                         code: 201,
        message: I18n.t("api.common.create_success"),
        resource: AdminNotificationSerializer.new(notification).serializable_hash,
        status: :created
                       })
    else
      unprocessable_entity(notification)
    end
  end

  def update
    if @notification.update(notification_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: AdminNotificationSerializer.new(@notification).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@notification)
    end
  end

  def destroy
    @notification.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
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

  def set_notification
    @notification = AdminNotification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def notification_params
    params.require(:admin_notification).permit(:title, :body, :link, :notification_type)
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
