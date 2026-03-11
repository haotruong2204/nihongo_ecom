# frozen_string_literal: true

class AddModesToTangoLessonProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :tango_lesson_progresses, :modes, :json
    add_column :tango_lesson_progresses, :available_modes, :json
  end
end
