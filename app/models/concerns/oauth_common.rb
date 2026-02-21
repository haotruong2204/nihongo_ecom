# frozen_string_literal: true

module OauthCommon
  PROVIDERS = { "google" => { uid_path: ["sub"] } }.freeze

  def create_user_for_provider provider, data
    provider_config = PROVIDERS[provider]
    raise "Unsupported provider: #{provider}" unless provider_config

    uid = data.dig(*provider_config[:uid_path])
    raise "UID not found in provider data" unless uid

    user = find_or_initialize_by(uid: uid, provider: provider)
    user.email = data["email"]
    user.display_name = data["name"] || data["display_name"]
    user.photo_url = data["picture"] || data["photo_url"]
    user.last_login_at = Time.current
    user.save!
    user
  end

  PROVIDERS.each_key do |provider|
    define_method("create_user_for_#{provider}") do |data|
      create_user_for_provider(provider, data)
    end
  end
end
