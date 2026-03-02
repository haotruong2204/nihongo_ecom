# frozen_string_literal: true

geoip_path = Rails.root.join("db/geoip/GeoLite2-City.mmdb")

if File.exist?(geoip_path)
  GEOIP_DB = MaxMindDB.new(geoip_path.to_s)
  Rails.logger.info("GeoIP database loaded: #{geoip_path}")
else
  GEOIP_DB = nil
  Rails.logger.warn("GeoIP database not found at #{geoip_path}. Run `rake geoip:download` to fetch it.")
end
