# In production, CORS is handled by nginx to ensure headers are present
# even on nginx-generated error responses (e.g. 503 rate limit).
# See nginx/nginx.conf for configuration.
#
# In development, rack-cors handles CORS so preflight OPTIONS requests work.
if Rails.env.development?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins "*"
      resource "*",
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head]
    end
  end
end
