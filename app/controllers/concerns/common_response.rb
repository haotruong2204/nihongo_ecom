# frozen_string_literal: true

module CommonResponse
  include ErrorCode
  SUCCESS_CODE = 200

  def response_success data = {}, message = I18n.t("api.common.success"), _obj = nil
    render_response(true, SUCCESS_CODE, message, data)
  end

  def response_error data = {}, code = BAD_REQUEST, message = I18n.t("api.common.fail")
    render_response(false, code, message, data)
  end

  def bad_request message = I18n.t("api.error.bad_request")
    response_error({}, BAD_REQUEST, message)
  end

  def unprocessable_entity entity = nil, message = I18n.t("api.error.unprocessable_entity")
    message = entity.errors.full_messages[0] if entity.present?
    response_error({}, UNPROCESSABLE_ENTITY, message)
  end

  def not_found message = I18n.t("api.error.not_found")
    response_error({}, NOT_FOUND, message)
  end

  def unauthorized message = I18n.t("api.error.unauthorized")
    response_error({}, UNAUTHORIZED, message)
  end

  private

  def render_response success, code, message, data
    body = { success:, code:, message:, data: }
    render status: code, json: body
  end
end
