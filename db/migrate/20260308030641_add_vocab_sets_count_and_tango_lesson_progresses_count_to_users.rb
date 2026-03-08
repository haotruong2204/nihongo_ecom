class AddVocabSetsCountAndTangoLessonProgressesCountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :vocab_sets_count, :integer, default: 0, null: false
    add_column :users, :tango_lesson_progresses_count, :integer, default: 0, null: false

    # Backfill existing counts
    User.find_each do |user|
      User.reset_counters(user.id, :vocab_sets, :tango_lesson_progresses)
    end
  end
end
