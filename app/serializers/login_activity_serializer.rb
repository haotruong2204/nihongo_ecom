# frozen_string_literal: true

class LoginActivitySerializer
  include JSONAPI::Serializer

  attributes :id, :ip_address, :user_agent, :device_info, :session_conflict, :country, :city, :created_at
end
