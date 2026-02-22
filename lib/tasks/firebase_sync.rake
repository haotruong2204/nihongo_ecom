# frozen_string_literal: true

namespace :firebase do
  desc "Sync all Firestore data to Rails database (full)"
  task sync: :environment do
    Rake::Task["firebase:sync_users"].invoke
    Rake::Task["firebase:sync_feedbacks"].invoke
    Rake::Task["firebase:sync_roadmap"].invoke(false)
    Rake::Task["firebase:sync_srs"].invoke(false)
    Rake::Task["firebase:sync_review_logs"].invoke(false)
    puts "\n=== All sync tasks completed (full) ==="
  end

  desc "Sync only active users (login within 10 days) from Firestore"
  task sync_active: :environment do
    Rake::Task["firebase:sync_users"].invoke
    Rake::Task["firebase:sync_feedbacks"].invoke
    Rake::Task["firebase:sync_roadmap"].invoke(true)
    Rake::Task["firebase:sync_srs"].invoke(true)
    Rake::Task["firebase:sync_review_logs"].invoke(true)
    puts "\n=== All sync tasks completed (active users only) ==="
  end

  desc "Sync Firestore users to Rails users table"
  task sync_users: :environment do
    service = FirebaseSyncService.new
    docs = service.fetch_collection("users")
    synced = 0
    skipped = 0

    puts "Syncing #{docs.size} users..."

    ActiveRecord::Base.transaction do
      docs.each do |doc|
        data = service.parse_document(doc)
        uid = service.document_id(doc)
        email = data["email"] || "#{uid}@firebase.local"

        user = User.find_or_initialize_by(uid: uid)

        # Nếu user mới mà email đã tồn tại ở user khác → skip
        if user.new_record? && User.exists?(email: email)
          skipped += 1
          next
        end

        user.assign_attributes(
          email: email,
          display_name: data["displayName"],
          photo_url: data["photoURL"],
          provider: data["provider"] || "google",
          is_premium: data["isPremium"] || false,
          premium_until: parse_timestamp(data["premiumUntil"]),
          last_login_at: parse_timestamp(data["lastLogin"])
        )

        if user.new_record?
          user.created_at = parse_timestamp(data["createdAt"]) if data["createdAt"]
        end

        user.save!
        synced += 1
      end
    end

    puts "Users synced: #{synced}/#{docs.size} (skipped #{skipped} duplicate emails)"
  end

  desc "Sync Firestore feedbacks to Rails feedbacks table"
  task sync_feedbacks: :environment do
    service = FirebaseSyncService.new
    docs = service.fetch_collection("feedbacks")
    synced = 0

    puts "Syncing #{docs.size} feedbacks..."

    # Pre-load user uid→id mapping
    user_map = User.pluck(:uid, :id).to_h

    ActiveRecord::Base.transaction do
      docs.each do |doc|
        data = service.parse_document(doc)
        user_id = user_map[data["uid"]] if data["uid"]

        status = map_feedback_status(data["status"])

        feedback = Feedback.find_or_initialize_by(
          text: data["text"],
          email: data["email"]
        )
        feedback.assign_attributes(
          user_id: user_id,
          display: data["display"] || false,
          status: status,
          admin_reply: data["reply"]
        )

        if feedback.admin_reply.present? && feedback.replied_at.nil?
          feedback.replied_at = Time.current
        end

        if feedback.new_record?
          feedback.created_at = parse_timestamp(data["createdAt"]) if data["createdAt"]
        end

        feedback.save!
        synced += 1
      end
    end

    puts "Feedbacks synced: #{synced}/#{docs.size}"
  end

  desc "Sync Firestore roadmap_progress to Rails roadmap_day_progresses table"
  task :sync_roadmap, [:active_only] => :environment do |_t, args|
    active_only = args[:active_only].to_s == "true"
    service = FirebaseSyncService.new
    docs = service.fetch_collection("roadmap_progress")
    synced = 0
    skipped = 0

    if active_only
      active_uids = User.where("last_login_at >= ?", 10.days.ago).pluck(:uid)
      puts "Syncing roadmap for #{active_uids.size} active users (from #{docs.size} docs)..."
    else
      puts "Syncing #{docs.size} roadmap_progress documents..."
    end

    user_map = User.pluck(:uid, :id).to_h

    ActiveRecord::Base.transaction do
      docs.each do |doc|
        uid = service.document_id(doc)
        data = service.parse_document(doc)
        user_id = user_map[uid]

        unless user_id
          skipped += 1
          next
        end

        if active_only && !active_uids.include?(uid)
          skipped += 1
          next
        end

        completed_days = data["completedDays"]
        next unless completed_days.is_a?(Hash)

        completed_days.each do |day_key, day_data|
          day_num = day_key.to_i
          next if day_num < 1 || day_num > 250

          kanji_learned = day_data.is_a?(Hash) ? day_data["kanjiLearned"] : nil
          completed_at = day_data.is_a?(Hash) ? parse_timestamp(day_data["completedAt"]) : nil

          # Default values if missing
          kanji_learned = kanji_learned.is_a?(Array) ? kanji_learned : []
          completed_at ||= Time.current

          progress = RoadmapDayProgress.find_or_initialize_by(user_id: user_id, day: day_num)
          progress.assign_attributes(
            kanji_learned: kanji_learned,
            completed_at: completed_at
          )
          progress.save!
          synced += 1
        end
      end
    end

    puts "Roadmap day progresses synced: #{synced} (skipped #{skipped} users not found)"
  end

  desc "Sync Firestore users/{uid}/srs subcollection to Rails srs_cards table"
  task :sync_srs, [:active_only] => :environment do |_t, args|
    active_only = args[:active_only].to_s == "true"
    service = FirebaseSyncService.new
    user_docs = service.fetch_collection("users")
    synced = 0
    skipped = 0
    errors = 0

    active_uids = active_only ? User.where("last_login_at >= ?", 10.days.ago).pluck(:uid) : nil
    target_count = active_only ? active_uids.size : user_docs.size
    puts "Syncing SRS cards for #{target_count} #{active_only ? 'active ' : ''}users..."

    user_map = User.pluck(:uid, :id).to_h

    user_docs.each_with_index do |user_doc, idx|
      uid = service.document_id(user_doc)
      user_id = user_map[uid]

      unless user_id
        skipped += 1
        next
      end

      if active_only && !active_uids.include?(uid)
        skipped += 1
        next
      end

      retries = 0
      begin
        parent_path = user_doc["name"]
        srs_docs = service.fetch_subcollection(parent_path, "srs")

        ActiveRecord::Base.transaction do
          srs_docs.each do |srs_doc|
            data = service.parse_document(srs_doc)
            kanji = data["kanji"] || service.document_id(srs_doc)

            state = map_srs_state(data["state"])

            card = SrsCard.find_or_initialize_by(user_id: user_id, kanji: kanji)
            card.assign_attributes(
              state: state,
              ease: (data["ease"] || 2.5).to_f.clamp(1.3, Float::INFINITY),
              interval: safe_unsigned_int(data["interval"] || 0),
              due_date: safe_timestamp(parse_timestamp(data["dueDate"])) || Time.current,
              reviews_count: safe_unsigned_int(data["reviews"] || 0),
              lapses_count: safe_unsigned_int(data["lapses"] || 0),
              last_review_at: parse_timestamp(data["lastReview"])
            )
            card.save!
            synced += 1
          end
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET => e
        retries += 1
        if retries <= 3
          puts "\n  Timeout for user #{uid}, retrying (#{retries}/3)..."
          sleep(2 * retries)
          retry
        else
          puts "\n  Failed for user #{uid} after 3 retries: #{e.message}"
          errors += 1
        end
      end

      print "\r  Processed #{idx + 1}/#{user_docs.size} users (#{synced} cards synced)"
    end

    puts "\nSRS cards synced: #{synced} (skipped #{skipped} users not found, #{errors} errors)"
  end

  desc "Sync Firestore users/{uid}/review_logs subcollection to Rails review_logs table"
  task :sync_review_logs, [:active_only] => :environment do |_t, args|
    active_only = args[:active_only].to_s == "true"
    service = FirebaseSyncService.new
    user_docs = service.fetch_collection("users")
    synced = 0
    skipped = 0
    errors = 0

    active_uids = active_only ? User.where("last_login_at >= ?", 10.days.ago).pluck(:uid) : nil
    target_count = active_only ? active_uids.size : user_docs.size
    puts "Syncing review logs for #{target_count} #{active_only ? 'active ' : ''}users..."

    user_map = User.pluck(:uid, :id).to_h

    user_docs.each_with_index do |user_doc, idx|
      uid = service.document_id(user_doc)
      user_id = user_map[uid]

      unless user_id
        skipped += 1
        next
      end

      if active_only && !active_uids.include?(uid)
        skipped += 1
        next
      end

      retries = 0
      begin
        parent_path = user_doc["name"]
        log_docs = service.fetch_subcollection(parent_path, "review_logs")

        ActiveRecord::Base.transaction do
          log_docs.each do |log_doc|
            data = service.parse_document(log_doc)
            reviewed_at = parse_timestamp(data["timestamp"]) || Time.current
            rating = map_review_rating(data["rating"])

            log = ReviewLog.find_or_initialize_by(
              user_id: user_id,
              kanji: data["kanji"],
              reviewed_at: reviewed_at
            )
            log.assign_attributes(
              rating: rating,
              interval_before: safe_unsigned_int(data["intervalBefore"] || 0),
              interval_after: safe_unsigned_int(data["intervalAfter"] || 0)
            )
            log.save!
            synced += 1
          end
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET => e
        retries += 1
        if retries <= 3
          puts "\n  Timeout for user #{uid}, retrying (#{retries}/3)..."
          sleep(2 * retries)
          retry
        else
          puts "\n  Failed for user #{uid} after 3 retries: #{e.message}"
          errors += 1
        end
      end

      print "\r  Processed #{idx + 1}/#{user_docs.size} users (#{synced} logs synced)"
    end

    puts "\nReview logs synced: #{synced} (skipped #{skipped} users not found, #{errors} errors)"
  end
end

# Helper methods

def parse_timestamp(value)
  return nil if value.nil?

  case value
  when Time, DateTime, ActiveSupport::TimeWithZone
    value
  when Integer
    # Firestore may store as milliseconds
    value > 9_999_999_999 ? Time.at(value / 1000.0) : Time.at(value)
  when String
    Time.parse(value)
  else
    nil
  end
rescue ArgumentError
  nil
end

MAX_MYSQL_DATETIME = Time.new(9999, 12, 31)
MIN_MYSQL_DATETIME = Time.new(1970, 1, 1)
MAX_UNSIGNED_INT = 4_294_967_295

def safe_timestamp(value)
  return nil if value.nil?

  value = value.to_time if value.respond_to?(:to_time)
  return nil unless value.is_a?(Time)

  value.clamp(MIN_MYSQL_DATETIME, MAX_MYSQL_DATETIME)
end

def safe_unsigned_int(value)
  val = value.to_i
  val.clamp(0, MAX_UNSIGNED_INT)
end

def map_srs_state(state_str)
  case state_str.to_s.downcase
  when "new" then :new_card
  when "learning" then :learning
  when "review" then :review
  when "relearning" then :relearning
  else :new_card
  end
end

def map_feedback_status(status_str)
  case status_str.to_s.downcase
  when "pending" then :pending
  when "reviewed" then :reviewed
  when "done" then :done
  when "rejected" then :rejected
  else :pending
  end
end

def map_review_rating(rating)
  case rating.to_s.downcase
  when "again", "1" then :again
  when "hard", "2" then :hard
  when "good", "3" then :good
  when "easy", "4" then :easy
  else :again
  end
end

