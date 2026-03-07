# frozen_string_literal: true

class Api::V1::Users::TangoLessonProgressesController < Api::V1::UserBaseController
  def index
    progresses = current_user.tango_lesson_progresses.for_book(params[:book_id]).order(:lesson_id)
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

    progress.assign_attributes(
      known_count: progress_params[:known_count],
      total_count: progress_params[:total_count],
      completed: progress_params[:completed],
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
    params.require(:tango_lesson_progress).permit(:book_id, :lesson_id, :known_count, :total_count, :completed)
  end
end
