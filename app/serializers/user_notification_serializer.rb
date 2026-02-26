# frozen_string_literal: true

class UserNotificationSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :title, :body, :link, :notification_type, :read, :created_by, :created_at

  attribute :user_email do |notification|
    notification.user&.email
  end

  attribute :user_display_name do |notification|
    notification.user&.display_name
  end
end
