# frozen_string_literal: true

class Api::V1::Admins::SessionsController < Devise::SessionsController
  include CommonResponse

  private

  def respond_with resource, _options = {}
    if resource.persisted?
      token = request.env["warden-jwt_auth.token"] || request.headers["Authorization"].to_s.split.last
      response_success({
                         code: 200,
                         message: I18n.t("api.common.success"),
                         resource: AdminSerializer.new(current_admin).serializable_hash,
                         token: token,
                         status: :ok
                       })
    else
      response_error({
                       code: 422,
                       message: I18n.t("api.common.fail"),
                       errors: resource.errors.full_messages,
                       status: :unprocessable_entity
                     })
    end
  end

  def respond_to_on_destroy
    token = request.headers["Authorization"].to_s.split.last
    return response_error(code: 401, message: I18n.t("api.common.fail"), status: :unauthorized) unless token

    begin
      payload = JWT.decode(token, ENV.fetch("DEVISE_JWT_SECRET_KEY"), true, algorithm: "HS256").first

      admin = Admin.find_by(id: payload["sub"])
      if admin&.jti == payload["jti"]
        response_success(code: 200, message: I18n.t("api.common.success"), status: :ok)
      else
        response_error(code: 401, message: I18n.t("api.common.fail"), status: :unauthorized)
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
      response_error(code: 401, message: I18n.t("api.common.fail"), status: :unauthorized)
    end
  end
end
