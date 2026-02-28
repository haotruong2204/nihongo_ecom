# frozen_string_literal: true

class Api::V1::Admins::QuickRepliesController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_quick_reply, only: [:show, :update, :destroy]

  def index
    q = QuickReply.ransack(params[:q])
    pagy, quick_replies = pagy(q.result.ordered, limit: params[:per_page] || 20)

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: QuickReplySerializer.new(quick_replies).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
    })
  end

  def show
    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: QuickReplySerializer.new(@quick_reply).serializable_hash,
      status: :ok
    })
  end

  def create
    quick_reply = QuickReply.new(quick_reply_params)

    if quick_reply.save
      response_success({
        code: 201,
        message: I18n.t("api.common.create_success"),
        resource: QuickReplySerializer.new(quick_reply).serializable_hash,
        status: :created
      })
    else
      unprocessable_entity(quick_reply)
    end
  end

  def update
    if @quick_reply.update(quick_reply_params)
      response_success({
        code: 200,
        message: I18n.t("api.common.update_success"),
        resource: QuickReplySerializer.new(@quick_reply).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(@quick_reply)
    end
  end

  def destroy
    @quick_reply.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_quick_reply
    @quick_reply = QuickReply.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def quick_reply_params
    params.require(:quick_reply).permit(:title, :content, :image_url, :position, :active)
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
