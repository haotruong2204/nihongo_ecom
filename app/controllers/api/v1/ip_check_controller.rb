# frozen_string_literal: true

class Api::V1::IpCheckController < ApplicationController
  include CommonResponse

  respond_to :json

  def show
    if BlockedIp.blocked?(request.remote_ip)
      render json: { blocked: true }, status: :forbidden
    else
      render json: { blocked: false }, status: :ok
    end
  end
end
