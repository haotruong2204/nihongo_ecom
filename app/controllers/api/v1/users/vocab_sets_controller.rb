# frozen_string_literal: true

class Api::V1::Users::VocabSetsController < Api::V1::UserBaseController
  before_action :set_vocab_set, only: [:show, :update, :destroy, :sync_items]

  # GET /api/v1/users/vocab_sets
  def index
    sets = current_user.vocab_sets.ordered

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: VocabSetSerializer.new(sets).serializable_hash,
      status: :ok
    })
  end

  # GET /api/v1/users/vocab_sets/:id
  def show
    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: VocabSetSerializer.new(@vocab_set).serializable_hash,
      status: :ok
    })
  end

  # POST /api/v1/users/vocab_sets
  def create
    set = current_user.vocab_sets.build(vocab_set_params)
    set.position = current_user.vocab_sets.count

    if set.save
      response_success({
        code: 200,
        message: I18n.t("api.common.create_success"),
        resource: VocabSetSerializer.new(set).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(set)
    end
  end

  # PATCH /api/v1/users/vocab_sets/:id
  def update
    if @vocab_set.update(vocab_set_params)
      response_success({
        code: 200,
        message: I18n.t("api.common.update_success"),
        resource: VocabSetSerializer.new(@vocab_set).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(@vocab_set)
    end
  end

  # DELETE /api/v1/users/vocab_sets/:id
  def destroy
    @vocab_set.destroy!
    response_success({ code: 200, message: I18n.t("api.common.delete_success"), status: :ok })
  end

  # PUT /api/v1/users/vocab_sets/:id/sync_items
  def sync_items
    items = params.require(:items).map do |item|
      item.permit(:word, :reading, :hanviet, :meaning).to_h
    end

    @vocab_set.update!(items: items)

    response_success({
      code: 200,
      message: I18n.t("api.common.update_success"),
      resource: VocabSetSerializer.new(@vocab_set).serializable_hash,
      status: :ok
    })
  rescue ActionController::ParameterMissing => e
    response_error({ code: 422, message: e.message, status: :unprocessable_entity })
  end

  private

  def set_vocab_set
    @vocab_set = current_user.vocab_sets.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def vocab_set_params
    params.require(:vocab_set).permit(:name, :position)
  end
end
