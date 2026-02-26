# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      reject_unauthorized_connection unless token

      payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY"), true, algorithm: "HS256").first

      user = Admin.find_by(id: payload["sub"], jti: payload["jti"]) ||
             User.find_by(id: payload["sub"], jti: payload["jti"])

      user || reject_unauthorized_connection
    rescue JWT::DecodeError, JWT::ExpiredSignature
      reject_unauthorized_connection
    end
  end
end
