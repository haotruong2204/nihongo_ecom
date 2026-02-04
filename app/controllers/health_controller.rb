# frozen_string_literal: true

class HealthController < ApplicationController
  def index
    # Basic health check - you can add more sophisticated checks here
    # like database connectivity, Redis connectivity, etc.

    # Check database connection
    ActiveRecord::Base.connection.execute("SELECT 1")

    # Check Redis connection (if using Redis)
    if defined?(Redis)
      redis_client = Redis.new(url: ENV["REDIS_URL"] || "redis://localhost:6379")
      redis_client.ping
    end

    render json: {
      status: "ok",
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name,
      environment: Rails.env
    }, status: :ok
  rescue StandardError => e
    render json: { status: "error", error: e.message, timestamp: Time.current.iso8601 }, status: :service_unavailable
  end
end
