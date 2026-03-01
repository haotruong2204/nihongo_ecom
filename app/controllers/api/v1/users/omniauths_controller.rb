# frozen_string_literal: true

class Api::V1::Users::OmniauthsController < Api::V1::UserBaseController
  skip_before_action :authenticate_user!, only: [:auth_google]

  def auth_google
    code = params[:code]
    return bad_request(I18n.t("api.error.bad_request")) unless code.present?

    oauth_service = OauthService.new
    access_token = oauth_service.access_token("google", code)
    user_data = oauth_service.oauth2_authorized(User::GOOGLE_API_INFO_ENDPOINT, access_token)

    user = User.create_user_for_google(user_data)

    is_new_user = user.login_activities.none?

    # Broadcast force_logout to existing sessions BEFORE regenerating jti
    unless is_new_user
      ActionCable.server.broadcast("user_notifications_#{user.id}", {
        type: "force_logout", reason: "new_login"
      })
    end

    # Regenerate jti → invalidate all old tokens
    user.update!(jti: SecureRandom.uuid)

    # Log login activity
    user.login_activities.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent&.truncate(500),
      device_info: parse_device_info(request.user_agent),
      session_conflict: !is_new_user
    )

    # Check conflict escalation
    if !is_new_user
      conflict_count = user.login_activities.conflicts.count

      if conflict_count >= 11 && !user.banned?
        # Auto-ban at 11th conflict
        user.update!(is_banned: true, banned_reason: "Tự động khóa: chia sẻ tài khoản (#{conflict_count} lần xung đột)")
      elsif (conflict_count % 10).zero?
        # Warn at every 10 conflicts
        UserNotification.notify_session_conflict_warning(user)
      end
    end

    # Generate new token with fresh jti
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: UserSerializer.new(user).serializable_hash,
                       token: token,
                       status: :ok
                     })
  rescue StandardError => e
    Rails.logger.error("Google OAuth error: #{e.message}")
    bad_request(e.message)
  end

  private

  def parse_device_info(ua)
    return "Unknown" if ua.blank?

    browser = case ua
              when /Edg/i then "Edge"
              when /Chrome/i then "Chrome"
              when /Firefox/i then "Firefox"
              when /Safari/i then "Safari"
              when /Opera|OPR/i then "Opera"
              else "Other"
              end

    os = case ua
         when /Windows/i then "Windows"
         when /Macintosh|Mac OS/i then "macOS"
         when /Linux/i then "Linux"
         when /Android/i then "Android"
         when /iPhone|iPad/i then "iOS"
         else "Other"
         end

    "#{browser} / #{os}"
  end
end
