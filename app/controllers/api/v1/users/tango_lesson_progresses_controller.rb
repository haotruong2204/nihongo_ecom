# frozen_string_literal: true

class Api::V1::Users::TangoLessonProgressesController < Api::V1::UserBaseController
  # GET /api/v1/users/tango_lesson_progresses?book_id=xxx
  # If book_id is omitted, returns all progresses for the user (premium sync)
  def index
    progresses = current_user.tango_lesson_progresses
    progresses = progresses.for_book(params[:book_id]) if params[:book_id].present?
    progresses = progresses.order(:book_id, :lesson_id)
    response_success({
      code: 200,
      message: I18n.t("api.common.success"),
      resource: TangoLessonProgressSerializer.new(progresses).serializable_hash,
      status: :ok
    })
  end

  # POST /api/v1/users/tango_lesson_progresses
  # Upsert: create or update progress for a lesson
  def create
    progress = current_user.tango_lesson_progresses.find_or_initialize_by(
      book_id: progress_params[:book_id],
      lesson_id: progress_params[:lesson_id]
    )

    # Merge modes: take max count per key (don't lose progress from other devices)
    merged_modes = (progress.modes || {}).merge(progress_params[:modes]&.to_h || {}) do |_key, old_val, new_val|
      [old_val.to_i, new_val.to_i].max
    end

    progress.assign_attributes(
      known_count: progress_params[:known_count],
      total_count: progress_params[:total_count],
      completed: progress_params[:completed],
      modes: merged_modes,
      available_modes: progress_params[:available_modes] || progress.available_modes,
      last_studied_at: Time.current
    )

    if progress.save
      response_success({
        code: 200,
        message: I18n.t("api.common.success"),
        resource: TangoLessonProgressSerializer.new(progress).serializable_hash,
        status: :ok
      })
    else
      unprocessable_entity(progress)
    end
  end

  private

  def progress_params
    params.require(:tango_lesson_progress).permit(
      :book_id, :lesson_id, :known_count, :total_count, :completed,
      modes: {}, available_modes: []
    )
  end
end
