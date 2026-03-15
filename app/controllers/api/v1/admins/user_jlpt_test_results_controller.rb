# frozen_string_literal: true

class Api::V1::Admins::UserJlptTestResultsController < Api::V1::BaseController
  include Pagy::Backend

  before_action :set_user

  def index
    scope = @user.jlpt_test_results.order(taken_at: :desc)
    scope = scope.where(level: params[:level]) if params[:level].present?
    scope = scope.where(passed: params[:passed] == "true") if params[:passed].present?
    pagy, results = pagy(scope, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
      message: I18n.t("api.common.success"),
      resource: JlptTestResultSerializer.new(results).serializable_hash,
      pagy: pagy_metadata(pagy),
      status: :ok
                     })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
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
