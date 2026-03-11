# frozen_string_literal: true

class Api::V1::Users::OmniauthsController < Api::V1::UserBaseController
  skip_before_action :authenticate_user!, only: [:auth_google]

  def auth_google # rubocop:disable Metrics/MethodLength,Metrics/PerceivedComplexity
    code = params[:code]
    return bad_request(I18n.t("api.error.bad_request")) unless code.present?

    oauth_service = OauthService.new
    access_token = oauth_service.access_token("google", code)
    user_data = oauth_service.oauth2_authorized(User::GOOGLE_API_INFO_ENDPOINT, access_token)

    user = User.create_user_for_google(user_data)

    current_device = request.headers["X-Device-ID"].presence || parse_device_info(request.user_agent)
    current_ip = request.remote_ip

    known_devices = user.login_activities.pluck(:device_info).uniq
    device_is_new = !known_devices.include?(current_device)
    is_conflict   = device_is_new && known_devices.size >= 3

    # Regenerate jti → invalidate all old tokens (existing sessions will fail on next API call)
    user.update!(jti: SecureRandom.uuid)

    # Log login activity
    user.login_activities.create!(
      ip_address: current_ip,
      user_agent: request.user_agent&.truncate(500),
      device_info: current_device,
      session_conflict: is_conflict,
      **geoip_attrs(current_ip)
    )

    # Chỉ band tài khoản premium khi vượt quá 3 thiết bị
    if is_conflict && !user.banned? && user.premium?
      user.update!(is_banned: true, banned_reason: "Có dấu hiệu vi phạm chính sách về tài khoản (chỉ 2 thiết bị)")
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

  def parse_device_info ua
    return "Unknown" if ua.blank?

    browser = case ua
              when /Brave/i then "Brave"
              when /Edg/i then "Edge"
              when /OPR|Opera/i then "Opera"
              when /SamsungBrowser/i then "Samsung"
              when /Firefox/i then "Firefox"
              when /Chrome/i then "Chrome"
              when /Safari/i then "Safari"
              else "Other"
              end

    # iOS must be checked before macOS — iOS UA contains "Mac OS X"
    os = case ua
         when /iPhone/i then "iOS"
         when /iPad/i then "iPadOS"
         when /Android/i then "Android"
         when /Windows/i then "Windows"
         when /Macintosh|Mac OS/i then "macOS"
         when /Linux/i then "Linux"
         else "Other"
         end

    device_type = if ua.match?(/Mobile/i) && !ua.match?(/iPad/i)
                    "Mobile"
                  elsif ua.match?(/iPad|Tablet/i)
                    "Tablet"
                  else
                    "Desktop"
                  end

    "#{browser} / #{os} / #{device_type}"
  end

  def geoip_attrs ip
    geo = GeoipLookupService.lookup(ip)
    return {} unless geo

    { country: geo[:country], city: geo[:city] }
  end
end
