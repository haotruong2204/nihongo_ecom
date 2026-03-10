# frozen_string_literal: true

class Api::V1::DevtoolsLogsController < ApplicationController
  include CommonResponse
  include ErrorCode

  respond_to :json

  def create
    ip = request.remote_ip
    user = try_authenticate

    # Track by IP + user combo: same IP with different users = separate records
    log = if user
            DevtoolsLog.find_or_initialize_by(ip_address: ip, user_id: user.id)
          else
            DevtoolsLog.find_or_initialize_by(ip_address: ip, user_id: nil)
          end

    log.open_count += 1 if log.persisted?
    log.user_agent = request.user_agent&.truncate(500)
    log.last_detected_at = Time.current

    if user
      log.email = user.email
    end

    # GeoIP lookup (only on first create or if missing)
    if log.country.blank?
      geo = GeoipLookupService.lookup(ip)
      if geo
        log.country = geo[:country]
        log.city = geo[:city]
      end
    end

    log.save!

    # Auto-ban IP if DevTools opened more than 5 times
    if log.open_count > 5 && !BlockedIp.exists?(ip_address: ip)
      BlockedIp.create!(
        ip_address: ip,
        reason: "Auto-banned: DevTools opened #{log.open_count} times"
      )
      ban_users_by_ip(ip)
    end

    head :no_content
  end

  private

  def ban_users_by_ip(ip_address)
    DevtoolsLog.where(ip_address: ip_address).where.not(user_id: nil).includes(:user).find_each do |log|
      user = log.user
      next if user.nil? || user.banned?

      user.update!(is_banned: true, banned_reason: "IP #{ip_address} blocked (DevTools auto-ban)")
      user.update!(jti: SecureRandom.uuid)
    end
  end

  def try_authenticate
    token = request.headers["Authorization"].to_s.split.last
    return nil unless token

    payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", nil), true, algorithm: "HS256").first
    user = User.find(payload["sub"])
    return nil unless user.jti == payload["jti"]

    user
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError, ActiveRecord::RecordNotFound
    nil
  end
end
