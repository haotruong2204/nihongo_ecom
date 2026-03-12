# frozen_string_literal: true

class Api::V1::Users::JlptTestResultsController < Api::V1::UserBaseController
  # GET /api/v1/users/jlpt_test_results?level=N3
  def index
    results = current_user.jlpt_test_results.recent
    results = results.for_level(params[:level]) if params[:level].present?

    # Aggregate pass/fail counts per test_id
    stats = current_user.jlpt_test_results
      .group(:test_id)
      .select(
        :test_id,
        "COUNT(*) AS total_attempts",
        "SUM(CASE WHEN passed = 1 THEN 1 ELSE 0 END) AS pass_count",
        "SUM(CASE WHEN passed = 0 THEN 1 ELSE 0 END) AS fail_count",
        "MAX(taken_at) AS last_taken_at"
      )

    stats_map = stats.each_with_object({}) do |s, h|
      h[s.test_id] = {
        total_attempts: s.total_attempts,
        pass_count: s.pass_count,
        fail_count: s.fail_count,
        last_taken_at: s.last_taken_at
      }
    end

    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: JlptTestResultSerializer.new(results).serializable_hash,
      stats: stats_map,
      status: :ok
    })
  end

  # POST /api/v1/users/jlpt_test_results
  def create
    result = current_user.jlpt_test_results.build(result_params)
    result.taken_at ||= Time.current

    if result.save
      response_success({
        code: 201,
        message: I18n.t("api.common.create_success"),
        resource: JlptTestResultSerializer.new(result).serializable_hash,
        status: :created
      })
    else
      unprocessable_entity(result)
    end
  end

  private

  def result_params
    params.require(:jlpt_test_result).permit(
      :test_id, :level, :section, :correct_count, :incorrect_count,
      :total_questions, :time_used, :time_limit, :passed, :taken_at,
      sections: [ :label, :correct, :total ]
    )
  end
end
