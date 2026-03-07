# frozen_string_literal: true

class Api::V1::Admins::UserCustomVocabItemsController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user
  before_action :set_item, only: [:destroy]

  def index
    q = @user.custom_vocab_items.ransack(params[:q])
    pagy, items = pagy(q.result.order(created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: CustomVocabItemSerializer.new(items).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def destroy
    @item.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def set_item
    @item = @user.custom_vocab_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
