# frozen_string_literal: true

class Api::V1::DevtoolsLogsController < ApplicationController
  include CommonResponse
  include ErrorCode

  respond_to :json

  def create
    ip = request.remote_ip
    user = try_authenticate

    log = DevtoolsLog.find_or_initialize_by(ip_address: ip)

    if log.persisted?
      log.open_count += 1
    end

    log.user_agent = request.user_agent&.truncate(500)
    log.last_detected_at = Time.current

    if user
      log.user = user
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

    head :no_content
  end

  private

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
