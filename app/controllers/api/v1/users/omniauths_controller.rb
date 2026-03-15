# frozen_string_literal: true

class Api::V1::Users::OmniauthsController < Api::V1::UserBaseController
  skip_before_action :authenticate_user!, only: [:auth_google]

  DEVICE_LIMIT = 2

  def auth_google # rubocop:disable Metrics/MethodLength
    code = params[:code]
    return bad_request(I18n.t("api.error.bad_request")) unless code.present?

    oauth_service = OauthService.new
    access_token = oauth_service.access_token("google", code)
    user_data = oauth_service.oauth2_authorized(User::GOOGLE_API_INFO_ENDPOINT, access_token)

    user = User.create_user_for_google(user_data)
    current_ip = request.remote_ip
    device_id = request.headers["X-Device-ID"].presence

    # Enforce device limit for premium users only
    if device_id.present? && user.premium?
      result = register_or_check_device(user, device_id, request.user_agent)
      if result == :limit_exceeded
        return render json: { message: "device_limit_exceeded" }, status: :unprocessable_entity
      end
    end

    # Log login activity for admin visibility
    user.login_activities.create!(
      ip_address: current_ip,
      user_agent: request.user_agent&.truncate(500),
      device_info: device_id.presence || parse_device_name(request.user_agent),
      session_conflict: false,
      **geoip_attrs(current_ip)
    )

    # Generate token (jti NOT regenerated — both devices remain valid simultaneously)
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

  def register_or_check_device(user, device_id, user_agent)
    device_name = parse_device_name(user_agent)
    existing = user.user_devices.find_by(device_id: device_id)

    if existing
      existing.update!(last_seen_at: Time.current, device_name: device_name)
      :found
    elsif user.user_devices.count >= DEVICE_LIMIT
      :limit_exceeded
    else
      user.user_devices.create!(device_id: device_id, device_name: device_name, last_seen_at: Time.current)
      :registered
    end
  end

  def parse_device_name(ua)
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

  def geoip_attrs(ip)
    geo = GeoipLookupService.lookup(ip)
    return {} unless geo

    { country: geo[:country], city: geo[:city] }
  end
end
