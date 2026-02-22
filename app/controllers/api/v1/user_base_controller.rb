# frozen_string_literal: true

class Api::V1::UserBaseController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!
  include CommonResponse
  include ErrorCode

  respond_to :json

  def authenticate_user!
    token = request.headers["Authorization"].to_s.split.last
    return unauthorized unless token

    begin
      payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY", nil), true, algorithm: "HS256").first
      user = User.find(payload["sub"])
      return unauthorized unless user.jti == payload["jti"]

      @current_user = user
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError, ActiveRecord::RecordNotFound
      unauthorized
    end
  end

  attr_reader :current_user

  private

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
