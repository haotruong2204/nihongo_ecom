# frozen_string_literal: true

class Rack::Attack
  ### Configure Cache ###

  # Use Redis if available, otherwise use Rails cache
  if ENV["REDIS_URL"].present?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
  else
    Rack::Attack.cache.store = Rails.cache
  end

  ### Throttle Strategies ###

  # Throttle login attempts by IP address
  # Limit: 5 requests per 60 seconds
  throttle("logins/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/api/v1/admins/sign_in" && req.post?
  end

  # Throttle login attempts by email (prevent brute force on single account)
  # Limit: 5 requests per 60 seconds
  throttle("logins/email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/api/v1/admins/sign_in" && req.post?
      # Extract email from request body
      begin
        body = JSON.parse(req.body.read)
        req.body.rewind
        body.dig("admin", "email")&.to_s&.downcase&.strip
      rescue JSON::ParserError
        nil
      end
    end
  end

  # Throttle password reset requests by IP
  # Limit: 3 requests per 60 seconds
  throttle("password_reset/ip", limit: 3, period: 60.seconds) do |req|
    req.ip if req.path == "/api/v1/admins/password" && req.post?
  end

  # General API rate limit by IP
  # Limit: 300 requests per 5 minutes
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  ### Blocklist ###

  # Block suspicious requests (SQL injection attempts, etc.)
  blocklist("block/malicious") do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      # Block if request contains suspicious patterns
      CGI.unescape(req.query_string).match?(/\bunion\b.*\bselect\b/i) ||
        req.path.include?("../") ||
        req.path.include?("etc/passwd")
    end
  end

  ### Custom Responses ###

  # Return 429 Too Many Requests with JSON response
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = Time.current

    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => (match_data[:period] - (now.to_i % match_data[:period])).to_s
    }

    body = {
      error: {
        code: 429,
        message: "Too many requests. Please retry after #{headers['Retry-After']} seconds.",
        throttle_key: req.env["rack.attack.matched"]
      }
    }.to_json

    [429, headers, [body]]
  end

  # Return 403 Forbidden for blocked requests
  self.blocklisted_responder = lambda do |_req|
    headers = { "Content-Type" => "application/json" }
    body = {
      error: {
        code: 403,
        message: "Your IP has been blocked due to suspicious activity."
      }
    }.to_json

    [403, headers, [body]]
  end
end

# Log throttled and blocked requests in development/production
ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn(
    "[Rack::Attack] Throttled #{req.env['rack.attack.matched']} from #{req.ip} - #{req.path}"
  )
end

ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn(
    "[Rack::Attack] Blocked #{req.env['rack.attack.matched']} from #{req.ip} - #{req.path}"
  )
end
