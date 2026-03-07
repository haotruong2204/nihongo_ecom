# frozen_string_literal: true

class Api::V1::Admins::UserVocabSetsController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user
  before_action :set_vocab_set, only: [:destroy, :remove_item]

  def index
    q = @user.vocab_sets.ransack(params[:q])
    pagy, sets = pagy(q.result.order(position: :asc, created_at: :desc), limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: VocabSetSerializer.new(sets).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  def destroy
    @vocab_set.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  def remove_item
    index = params[:index].to_i
    items = @vocab_set.items || []

    return render json: { error: "Index out of range" }, status: :unprocessable_entity if index < 0 || index >= items.size

    items.delete_at(index)
    @vocab_set.update!(items: items)

    response_success({
      code: 200,
      message: I18n.t("api.common.update_success"),
      resource: VocabSetSerializer.new(@vocab_set).serializable_hash,
      status: :ok
    })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def set_vocab_set
    @vocab_set = @user.vocab_sets.find(params[:id])
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
