# frozen_string_literal: true

class Api::V1::Admins::ChatNotificationsController < Api::V1::BaseController
  def create
    uid = params[:uid].to_s
    message_text = params[:message].to_s.truncate(100)
    return bad_request("uid is required") if uid.blank?

    user = User.find_by(uid: uid)
    return response_success({ code: 200, message: "User not found, skip push" }) unless user

    WebPushService.send_to_user(user, {
      title: "Nhai Kanji",
      body: message_text.presence || "Bạn có tin nhắn mới!",
      icon: "/icon-192.png",
      badge: "/icon-192.png",
      url: "/?chat=open"
    })

    response_success({ code: 200, message: "Push sent", status: :ok })
  end
end
