class ResponseEncryptor
  SKIP_PATHS = %w[/health /api-docs].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    if should_encrypt?(env, headers)
      body = extract_body(response)
      encrypted = EncryptionService.encrypt(body)
      encrypted_json = encrypted.to_json

      headers["Content-Type"] = "application/json; charset=utf-8"
      headers["Content-Length"] = encrypted_json.bytesize.to_s
      headers["X-Encrypted"] = "true"

      response = [ encrypted_json ]
    end

    [ status, headers, response ]
  end

  private

  def should_encrypt?(env, headers)
    path = env["PATH_INFO"]

    return false unless path&.start_with?("/api/")
    return false if skip_path?(path)
    return false unless json_response?(headers)
    return false if skip_encryption_header?(env)
    return false unless rsa_key_configured?

    true
  end

  def skip_path?(path)
    SKIP_PATHS.any? { |skip| path.start_with?(skip) }
  end

  def json_response?(headers)
    content_type = headers["Content-Type"].to_s
    content_type.include?("application/json")
  end

  def skip_encryption_header?(env)
    Rails.env.development? && env["HTTP_X_SKIP_ENCRYPTION"] == "true"
  end

  def rsa_key_configured?
    ENV["RSA_PUBLIC_KEY"].present?
  end

  def extract_body(response)
    body = +""
    response.each { |part| body << part }
    response.close if response.respond_to?(:close)
    body
  end
end
