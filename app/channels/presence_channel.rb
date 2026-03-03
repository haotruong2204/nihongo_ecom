# frozen_string_literal: true

class PresenceChannel < ApplicationCable::Channel
  PRESENCE_TTL = 90

  def subscribed
    if current_user.is_a?(User)
      set_online
      stream_from "presence_user_#{current_user.id}"
    elsif current_user.is_a?(Admin)
      stream_from "admin_presence"
    else
      reject
    end
  end

  def unsubscribed
    return unless current_user.is_a?(User)

    REDIS.del(presence_key)
    broadcast_presence_change(false)
  end

  def heartbeat
    return unless current_user.is_a?(User)

    set_online
  end

  private

  def set_online
    was_online = REDIS.exists?(presence_key)
    REDIS.setex(presence_key, PRESENCE_TTL, Time.current.to_i)
    broadcast_presence_change(true) unless was_online
  end

  def broadcast_presence_change(is_online)
    ActionCable.server.broadcast("admin_presence", {
      type: "presence_change",
      user_id: current_user.id,
      is_online: is_online
    })
  end

  def presence_key
    "presence:user:#{current_user.id}"
  end
end
