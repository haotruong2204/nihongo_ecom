# frozen_string_literal: true

class Api::V1::Admins::DashboardController < Api::V1::BaseController
  def home
    render json: { message: "Welcome to the Admin Dashboard" }, status: :ok
  end
end
