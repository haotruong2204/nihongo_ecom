# frozen_string_literal: true

class DevtoolsLogSerializer
  include JSONAPI::Serializer

  attributes :id, :ip_address, :user_agent, :email, :open_count, :last_detected_at, :created_at

  belongs_to :user
end
