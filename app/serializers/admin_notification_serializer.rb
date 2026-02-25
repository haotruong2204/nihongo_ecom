# frozen_string_literal: true

class AdminNotificationSerializer
  include JSONAPI::Serializer

  attributes :id, :title, :body, :link, :notification_type, :read, :created_at
end
