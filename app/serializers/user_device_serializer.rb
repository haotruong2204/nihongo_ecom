# frozen_string_literal: true

class UserDeviceSerializer
  include JSONAPI::Serializer

  attributes :device_id, :device_name, :last_seen_at, :created_at
end
