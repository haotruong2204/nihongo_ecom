# frozen_string_literal: true

class Api::V1::Users::QuickRepliesController < Api::V1::UserBaseController
  def index
    quick_replies = QuickReply.active.ordered

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: QuickReplySerializer.new(quick_replies).serializable_hash,
      status: :ok
    })
  end
end
