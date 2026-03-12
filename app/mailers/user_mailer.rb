# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def premium_expiry_reminder(user)
    @user = user
    @days_left = (user.premium_until.to_date - Date.current).to_i
    mail(to: user.email, subject: "⏳ Tài khoản Premium NhaiKanji sắp hết hạn")
  end
end
