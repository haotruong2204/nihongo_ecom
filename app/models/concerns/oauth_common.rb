# frozen_string_literal: true

module OauthCommon
  PROVIDERS = { "google" => { uid_path: ["sub"] } }.freeze

  def create_user_for_provider provider, data
    provider_config = PROVIDERS[provider]
    raise "Unsupported provider: #{provider}" unless provider_config

    uid = data.dig(*provider_config[:uid_path])
    raise "UID not found in provider data" unless uid

    # Find by uid first, then fall back to email (handles Firebase-synced users)
    user = find_by(uid: uid, provider: provider) ||
           find_by(email: data["email"]) ||
           new(provider: provider)
    is_new_user = user.new_record?
    user.uid = uid
    user.email = data["email"]
    user.display_name = data["name"] || data["display_name"]
    user.photo_url = data["picture"] || data["photo_url"]
    user.last_login_at = Time.current
    user.save!
    UserNotification.create_welcome(user) if is_new_user
    user
  end

  PROVIDERS.each_key do |provider|
    define_method("create_user_for_#{provider}") do |data|
      create_user_for_provider(provider, data)
    end
  end
end
