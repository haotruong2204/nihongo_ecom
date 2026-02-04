# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  before do
    # Clear Rack::Attack cache before each test
    Rack::Attack.cache.store.clear
  end

  describe "login throttling" do
    let(:login_path) { "/api/v1/admins/sign_in" }
    let(:valid_params) { { admin: { email: "test@example.com", password: "password123" } } }

    context "when exceeding rate limit by IP" do
      it "blocks requests after 5 attempts" do
        6.times do |i|
          post login_path, params: valid_params, as: :json

          if i < 5
            expect(response.status).not_to eq(429)
          else
            expect(response.status).to eq(429)
            expect(JSON.parse(response.body)["error"]["message"]).to include("Too many requests")
          end
        end
      end
    end

    context "when exceeding rate limit by email" do
      it "blocks requests for same email after 5 attempts" do
        6.times do |i|
          post login_path, params: valid_params, as: :json

          if i < 5
            expect(response.status).not_to eq(429)
          else
            expect(response.status).to eq(429)
          end
        end
      end
    end

    context "when under rate limit" do
      it "allows requests" do
        3.times do
          post login_path, params: valid_params, as: :json
          expect(response.status).not_to eq(429)
        end
      end
    end
  end

  describe "general API throttling" do
    let(:api_path) { "/api/v1/admins/me" }

    context "when exceeding general API rate limit" do
      it "blocks after 300 requests" do
        # This test is skipped in CI due to performance
        skip "Skipping high-volume rate limit test" if ENV["CI"]

        301.times do |i|
          get api_path

          if i < 300
            expect(response.status).not_to eq(429)
          else
            expect(response.status).to eq(429)
          end
        end
      end
    end
  end

  describe "blocklist" do
    it "blocks requests with SQL injection patterns" do
      get "/api/v1/admins/me?id=1%20UNION%20SELECT%20*%20FROM%20users"
      # First request may not be blocked, but subsequent ones will be
      3.times do
        get "/api/v1/admins/me?id=1%20UNION%20SELECT%20*%20FROM%20users"
      end
      get "/api/v1/admins/me?id=1%20UNION%20SELECT%20*%20FROM%20users"
      expect(response.status).to eq(403)
    end

    it "blocks requests with path traversal" do
      3.times do
        get "/api/v1/../../../etc/passwd"
      end
      get "/api/v1/../../../etc/passwd"
      expect(response.status).to eq(403)
    end
  end
end
