# frozen_string_literal: true

class AddFeedbackIdToUserNotifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :user_notifications, :feedback, null: true, foreign_key: { on_delete: :cascade }
  end
end
