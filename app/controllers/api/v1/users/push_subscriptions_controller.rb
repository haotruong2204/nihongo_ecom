# frozen_string_literal: true

class Api::V1::Users::PushSubscriptionsController < Api::V1::BaseController
  def create
    sub = current_user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    sub.assign_attributes(p256dh_key: params[:p256dh], auth_key: params[:auth])

    if sub.save
      response_success({ code: 201, message: "Subscribed", status: :created })
    else
      unprocessable_entity(sub)
    end
  end

  def destroy
    sub = current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
    sub&.destroy
    response_success({ code: 200, message: "Unsubscribed", status: :ok })
  end
end
