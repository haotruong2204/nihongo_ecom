# frozen_string_literal: true

class FeedbackChannel < ApplicationCable::Channel
  def subscribed
    if current_user.is_a?(Admin)
      stream_from "admin_feedbacks"
    elsif current_user.is_a?(User)
      stream_from "user_feedbacks_#{current_user.id}"
    else
      reject
    end
  end
end
