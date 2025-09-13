# frozen_string_literal: true

class Api::V1::BaseController < ApplicationController
  before_action :authenticate_admin!
  include CommonResponse
  include ErrorCode
  include Devise::Controllers::Helpers

  respond_to :json

  def authenticate_admin!
    token = request.headers["Authorization"].to_s.split.last
    return unauthorized unless token

    begin
      payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", nil), true, algorithm: "HS256").first
      admin = Admin.find(payload["sub"])
      return unauthorized unless admin.jti == payload["jti"]

      @current_admin = admin
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
      unauthorized
    end
  end
end
