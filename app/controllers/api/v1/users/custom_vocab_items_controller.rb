# frozen_string_literal: true

class Api::V1::Users::CustomVocabItemsController < Api::V1::UserBaseController
  before_action :set_custom_vocab_item, only: [:show, :update, :destroy]

  def index
    q = current_user.custom_vocab_items.ransack(params[:q])
    pagy, items = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: CustomVocabItemSerializer.new(items).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def show
    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: CustomVocabItemSerializer.new(@custom_vocab_item).serializable_hash,
      status: :ok
                     })
  end

  def create
    item = current_user.custom_vocab_items.build(custom_vocab_item_params)

    if item.save
      response_success({
                         code: 200,
        message: I18n.t("api.common.create_success"),
        resource: CustomVocabItemSerializer.new(item).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(item)
    end
  end

  def update
    if @custom_vocab_item.update(custom_vocab_item_params)
      response_success({
                         code: 200,
        message: I18n.t("api.common.update_success"),
        resource: CustomVocabItemSerializer.new(@custom_vocab_item).serializable_hash,
        status: :ok
                       })
    else
      unprocessable_entity(@custom_vocab_item)
    end
  end

  def destroy
    @custom_vocab_item.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_custom_vocab_item
    @custom_vocab_item = current_user.custom_vocab_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def custom_vocab_item_params
    params.require(:custom_vocab_item).permit(:word, :reading, :hanviet, :meaning, :position)
  end
end
