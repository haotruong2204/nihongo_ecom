# frozen_string_literal: true

class GeoipLookupService
  PRIVATE_IP_RANGES = [
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("::1/128")
  ].freeze

  def self.country(ip)
    lookup(ip)&.dig(:country)
  end

  def self.city(ip)
    lookup(ip)&.dig(:city)
  end

  def self.lookup(ip)
    return nil if ip.blank?
    return nil if GEOIP_DB.nil?
    return nil if private_ip?(ip)

    result = GEOIP_DB.lookup(ip)
    return nil unless result&.found?

    { country: result.country.name, city: result.city.name }
  rescue StandardError => e
    Rails.logger.warn("GeoIP lookup failed for #{ip}: #{e.message}")
    nil
  end

  def self.private_ip?(ip)
    addr = IPAddr.new(ip)
    PRIVATE_IP_RANGES.any? { |range| range.include?(addr) }
  rescue IPAddr::InvalidAddressError
    true
  end

  private_class_method :private_ip?
end
