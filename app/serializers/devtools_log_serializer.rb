# frozen_string_literal: true

class DevtoolsLogSerializer
  include JSONAPI::Serializer

  attributes :id, :ip_address, :user_agent, :email, :open_count, :country, :city, :last_detected_at, :created_at

  attribute :is_blocked do |log|
    BlockedIp.exists?(ip_address: log.ip_address)
  end

  attribute :blocked_ip_id do |log|
    BlockedIp.find_by(ip_address: log.ip_address)&.id
  end

  belongs_to :user
end
