# frozen_string_literal: true

class Api::V1::Admins::ChatRoomsController < Api::V1::BaseController
  def index
    uids = Array(params[:uids]).map(&:to_s).uniq
    return bad_request("uids is required") if uids.blank?

    # Auto-create ChatRoom records for new uids
    existing = ChatRoom.where(uid: uids).pluck(:uid)
    (uids - existing).each { |uid| ChatRoom.create(uid: uid) }

    # Re-link rooms that have no user yet
    ChatRoom.where(uid: uids, user_id: nil).find_each do |room|
      user = User.find_by(uid: room.uid)
      room.update_column(:user_id, user.id) if user
    end

    # Fresh query with eager-loaded user
    rooms = ChatRoom.includes(:user).where(uid: uids)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: ChatRoomSerializer.new(rooms).serializable_hash
                     })
  end

  def update
    room = ChatRoom.find_by(uid: params[:uid])
    return not_found unless room

    if room.update(chat_room_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: ChatRoomSerializer.new(room).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(room)
    end
  end

  private

  def chat_room_params
    params.require(:chat_room).permit(:status, :admin_note, :chat_banned, :chat_ban_reason,
      :last_opened_at, :last_admin_reply_at, :last_user_message_at)
  end
end
