# frozen_string_literal: true

class OauthService
  PROVIDERS = {
    "google" => {
      client_id: ENV.fetch("GOOGLE_CLIENT_ID", nil),
      client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
      token_endpoint: ENV.fetch("GOOGLE_TOKEN_ENDPOINT", "https://oauth2.googleapis.com/token"),
      redirect_uri: ENV.fetch("GOOGLE_REDIRECT_URI", nil)
    }
  }.freeze

  def access_token provider, code
    config = provider_config(provider)

    response = HTTParty.post(config[:token_endpoint], {
                               body: {
                                 code: code,
                                 client_id: config[:client_id],
                                 client_secret: config[:client_secret],
                                 redirect_uri: config[:redirect_uri],
                                 grant_type: "authorization_code"
                               }
                             })

    raise "Failed to exchange code for token: #{response.body}" unless response.success?

    response.parsed_response["access_token"]
  end

  def oauth2_authorized endpoint, access_token
    response = HTTParty.get(endpoint, { headers: { "Authorization" => "Bearer #{access_token}" } })

    raise "Failed to fetch user info: #{response.body}" unless response.success?

    response.parsed_response
  end

  private

  def provider_config provider
    config = PROVIDERS[provider]
    raise "Unsupported provider: #{provider}" unless config

    config
  end
end
