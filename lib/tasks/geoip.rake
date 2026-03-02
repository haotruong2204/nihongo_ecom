# frozen_string_literal: true

namespace :geoip do
  desc "Download GeoLite2-Country database from MaxMind"
  task download: :environment do
    account_id = ENV["MAXMIND_ACCOUNT_ID"]
    license_key = ENV["MAXMIND_LICENSE_KEY"]
    abort "ERROR: Set MAXMIND_ACCOUNT_ID and MAXMIND_LICENSE_KEY environment variables. Get them at https://www.maxmind.com/en/geolite2/signup" if account_id.blank? || license_key.blank?

    require "open-uri"
    require "tmpdir"

    edition = "GeoLite2-City"
    dest_dir = Rails.root.join("db/geoip")
    dest_file = dest_dir.join("#{edition}.mmdb")
    url = "https://download.maxmind.com/geoip/databases/#{edition}/download?suffix=tar.gz"

    puts "Downloading #{edition} database..."

    Dir.mktmpdir do |tmpdir|
      tar_path = File.join(tmpdir, "#{edition}.tar.gz")

      URI.parse(url).open(http_basic_authentication: [account_id, license_key]) do |remote|
        File.open(tar_path, "wb") { |f| f.write(remote.read) }
      end

      puts "Extracting..."
      system("tar", "-xzf", tar_path, "-C", tmpdir) || abort("Failed to extract archive")

      mmdb_file = Dir.glob("#{tmpdir}/**/#{edition}.mmdb").first
      abort "ERROR: #{edition}.mmdb not found in archive" unless mmdb_file

      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(mmdb_file, dest_file)

      puts "Saved to #{dest_file}"
    end
  end

  desc "Backfill country and city for existing login activities"
  task backfill: :environment do
    abort "ERROR: GeoIP database not loaded. Run `rake geoip:download` first." if GEOIP_DB.nil?

    records = LoginActivity.where(country: nil).where.not(ip_address: nil)
    total = records.count
    puts "Backfilling geo data for #{total} login activities..."

    updated = 0
    records.find_each do |activity|
      geo = GeoipLookupService.lookup(activity.ip_address)
      if geo.present?
        activity.update_columns(country: geo[:country], city: geo[:city])
        updated += 1
      end
    end

    puts "Done. Updated #{updated}/#{total} records."
  end
end
