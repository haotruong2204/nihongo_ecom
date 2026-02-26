# frozen_string_literal: true

class Api::V1::Admins::UserNotificationsController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_notification, only: [:show, :update, :destroy]

  def index
    q = UserNotification.ransack(params[:q])
    pagy, records = pagy(q.result.recent, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserNotificationSerializer.new(records).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: UserNotificationSerializer.new(@notification).serializable_hash,
      status: :ok
                     })
  end

  def create
    if params[:send_to] == "all"
      notifications = User.find_each.map do |user|
        UserNotification.create!(notification_params.merge(user_id: user.id, created_by: "admin"))
      end

      response_success({
                         code: 201,
        message: I18n.t("api.common.create_success"),
        resource: UserNotificationSerializer.new(notifications).serializable_hash,
        status: :created
                       })
    else
      notification = UserNotification.new(notification_params.merge(created_by: "admin"))

      if notification.save
        response_success({
                           code: 201,
          message: I18n.t("api.common.create_success"),
          resource: UserNotificationSerializer.new(notification).serializable_hash,
          status: :created
                         })
      else
        unprocessable_entity(notification)
      end
    end
  end

  def update
    if @notification.update(notification_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: UserNotificationSerializer.new(@notification).serializable_hash,
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

  private

  def set_notification
    @notification = UserNotification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def notification_params
    params.require(:user_notification).permit(:user_id, :title, :body, :link, :notification_type)
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
