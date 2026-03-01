# frozen_string_literal: true

class LoginActivitySerializer
  include JSONAPI::Serializer

  attributes :id, :ip_address, :user_agent, :device_info, :session_conflict, :created_at
end
