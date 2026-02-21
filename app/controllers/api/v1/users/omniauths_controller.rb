# frozen_string_literal: true

class Api::V1::Users::OmniauthsController < Api::V1::UserBaseController
  skip_before_action :authenticate_user!, only: [:auth_google]

  def auth_google
    code = params[:code]
    return bad_request(I18n.t("api.error.bad_request")) unless code.present?

    oauth_service = OauthService.new
    access_token = oauth_service.access_token("google", code)
    user_data = oauth_service.oauth2_authorized(User::GOOGLE_API_INFO_ENDPOINT, access_token)

    user = User.create_user_for_google(user_data)
    return response_error({}, 403, user.banned_reason || I18n.t("api.error.forbidden")) if user.banned?

    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: UserSerializer.new(user).serializable_hash,
                       token: token,
                       status: :ok
                     })
  rescue StandardError => e
    Rails.logger.error("Google OAuth error: #{e.message}")
    bad_request(e.message)
  end
end
