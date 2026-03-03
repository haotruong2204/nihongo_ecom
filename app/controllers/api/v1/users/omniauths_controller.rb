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

    last_login = user.login_activities.order(created_at: :desc).first
    current_device = parse_device_info(request.user_agent)
    current_ip = request.remote_ip

    is_conflict = last_login.present? &&
      (last_login.device_info != current_device || last_login.ip_address != current_ip)

    # Broadcast force_logout to existing sessions BEFORE regenerating jti
    if is_conflict
      ActionCable.server.broadcast("user_notifications_#{user.id}", {
        type: "force_logout", reason: "new_login"
      })
    end

    # Regenerate jti → invalidate all old tokens
    user.update!(jti: SecureRandom.uuid)

    # Log login activity
    user.login_activities.create!(
      ip_address: current_ip,
      user_agent: request.user_agent&.truncate(500),
      device_info: current_device,
      session_conflict: is_conflict,
      **geoip_attrs(current_ip)
    )

    # Check conflict escalation
    if is_conflict
      conflict_count = user.login_activities.conflicts.count

      if conflict_count >= 21 && !user.banned?
        user.update!(is_banned: true, banned_reason: "Tự động khóa: chia sẻ tài khoản (#{conflict_count} lần xung đột)")
      elsif (conflict_count % 20).zero?
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

  def geoip_attrs(ip)
    geo = GeoipLookupService.lookup(ip)
    return {} unless geo

    { country: geo[:country], city: geo[:city] }
  end
end
