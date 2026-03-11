# frozen_string_literal: true

class Api::V1::Users::StudyAlertsController < Api::V1::UserBaseController
  THRESHOLD_FREE    = 30
  THRESHOLD_PREMIUM = 50

  def create
    threshold = current_user.premium? ? THRESHOLD_PREMIUM : THRESHOLD_FREE
    count = params[:count].to_i
    return head :no_content if count < threshold

    # Avoid spamming: skip if a study_fast notification was already sent in the last hour
    recent = current_user.user_notifications
                         .where(notification_type: "study_fast")
                         .where("created_at > ?", 1.hour.ago)
                         .exists?
    UserNotification.notify_study_fast(current_user) unless recent

    head :no_content
  end
end
