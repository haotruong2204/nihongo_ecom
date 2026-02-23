# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SES_SENDER_EMAIL", "noreply@nhaikanji.com")
  layout "mailer"
end
