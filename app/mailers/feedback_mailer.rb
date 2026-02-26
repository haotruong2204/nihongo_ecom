# frozen_string_literal: true

class FeedbackMailer < ApplicationMailer
  def reply_notification feedback
    @feedback = feedback
    mail(to: @feedback.email, subject: "Phản hồi từ NhaiKanji về góp ý của bạn")
  end
end
