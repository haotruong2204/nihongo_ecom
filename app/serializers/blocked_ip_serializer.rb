# frozen_string_literal: true

class BlockedIpSerializer
  include JSONAPI::Serializer

  attributes :id, :ip_address, :reason, :created_at
end
