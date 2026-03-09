# frozen_string_literal: true

class Api::V1::Users::StudyAlertsController < Api::V1::UserBaseController
  def create
    # Avoid spamming: skip if a study_fast notification was already sent in the last hour
    recent = current_user.user_notifications
                         .where(notification_type: "study_fast")
                         .where("created_at > ?", 1.hour.ago)
                         .exists?
    UserNotification.notify_study_fast(current_user) unless recent

    head :no_content
  end
end
