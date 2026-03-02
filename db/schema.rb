# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_02_110001) do
  create_table "admin_notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.string "link"
    t.string "notification_type", default: "feedback", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "created_by", default: "system", null: false
    t.index ["created_at"], name: "index_admin_notifications_on_created_at"
    t.index ["read"], name: "index_admin_notifications_on_read"
  end

  create_table "admins", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["jti"], name: "index_admins_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "chat_rooms", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.bigint "user_id"
    t.string "status", default: "open"
    t.datetime "last_admin_reply_at"
    t.datetime "last_user_message_at"
    t.datetime "last_opened_at"
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "chat_banned", default: false, null: false
    t.string "chat_ban_reason", limit: 500
    t.index ["status"], name: "index_chat_rooms_on_status"
    t.index ["uid"], name: "index_chat_rooms_on_uid", unique: true
    t.index ["user_id"], name: "index_chat_rooms_on_user_id"
  end

  create_table "contacts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name", null: false
    t.string "phone", limit: 50, null: false
    t.string "level", limit: 50
    t.string "email"
    t.string "source", limit: 100, default: "khoa-hoc", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "custom_vocab_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "word", null: false
    t.string "reading", null: false
    t.string "hanviet", default: "", null: false
    t.string "meaning", limit: 500, null: false
    t.integer "position", default: 0, null: false, unsigned: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "position"], name: "index_custom_vocab_items_on_user_id_and_position"
    t.index ["user_id", "word"], name: "index_custom_vocab_items_on_user_id_and_word", unique: true
    t.index ["user_id"], name: "index_custom_vocab_items_on_user_id"
  end

  create_table "daily_request_stats", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.integer "total_requests", default: 0, null: false
    t.json "endpoint_stats"
    t.boolean "flagged", default: false, null: false
    t.string "flag_reason", limit: 200
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_daily_request_stats_on_user_id_and_date", unique: true
    t.index ["user_id"], name: "index_daily_request_stats_on_user_id"
  end

  create_table "feedbacks", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "email"
    t.text "text", null: false
    t.boolean "display", default: false, null: false
    t.integer "status", limit: 1, default: 0, null: false
    t.text "admin_reply"
    t.datetime "replied_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.string "context_type"
    t.string "context_id"
    t.string "context_label"
    t.string "photo_url"
    t.string "display_name"
    t.index ["context_type", "context_id"], name: "index_feedbacks_on_context_type_and_context_id"
    t.index ["created_at"], name: "index_feedbacks_on_created_at"
    t.index ["parent_id"], name: "index_feedbacks_on_parent_id"
    t.index ["status"], name: "index_feedbacks_on_status"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "jlpt_test_results", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "level", limit: 10, null: false
    t.integer "correct_count", null: false, unsigned: true
    t.integer "incorrect_count", null: false, unsigned: true
    t.integer "total_questions", default: 35, null: false, unsigned: true
    t.integer "time_used", null: false, unsigned: true
    t.integer "time_limit", default: 1800, null: false, unsigned: true
    t.boolean "passed", null: false
    t.json "sections", null: false
    t.datetime "taken_at", null: false
    t.datetime "created_at", null: false
    t.index ["user_id", "level"], name: "index_jlpt_test_results_on_user_id_and_level"
    t.index ["user_id", "taken_at"], name: "index_jlpt_test_results_on_user_id_and_taken_at"
    t.index ["user_id"], name: "index_jlpt_test_results_on_user_id"
  end

  create_table "login_activities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address", limit: 45
    t.string "user_agent", limit: 500
    t.string "device_info", limit: 200
    t.boolean "session_conflict", default: false, null: false
    t.datetime "created_at", null: false
    t.string "country", limit: 100
    t.string "city", limit: 100
    t.index ["user_id", "created_at"], name: "index_login_activities_on_user_id_and_created_at"
    t.index ["user_id", "session_conflict"], name: "index_login_activities_on_user_id_and_session_conflict"
    t.index ["user_id"], name: "index_login_activities_on_user_id"
  end

  create_table "quick_replies", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
    t.index ["active"], name: "index_quick_replies_on_active"
    t.index ["position"], name: "index_quick_replies_on_position"
  end

  create_table "review_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kanji", limit: 10, null: false
    t.integer "rating", limit: 1, null: false
    t.integer "interval_before", default: 0, null: false, unsigned: true
    t.integer "interval_after", default: 0, null: false, unsigned: true
    t.datetime "reviewed_at", null: false
    t.datetime "created_at", null: false
    t.integer "duration_ms", unsigned: true
    t.index ["user_id", "kanji"], name: "index_review_logs_on_user_id_and_kanji"
    t.index ["user_id", "reviewed_at"], name: "index_review_logs_on_user_id_and_reviewed_at"
    t.index ["user_id"], name: "index_review_logs_on_user_id"
  end

  create_table "roadmap_day_progresses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "day", null: false, unsigned: true
    t.json "kanji_learned", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "completed_at"], name: "index_roadmap_day_progresses_on_user_id_and_completed_at"
    t.index ["user_id", "day"], name: "index_roadmap_day_progresses_on_user_id_and_day", unique: true
    t.index ["user_id"], name: "index_roadmap_day_progresses_on_user_id"
  end

  create_table "srs_cards", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kanji", limit: 10, null: false
    t.integer "state", limit: 1, default: 0, null: false
    t.decimal "ease", precision: 4, scale: 2, default: "2.5", null: false
    t.integer "interval", default: 0, null: false, unsigned: true
    t.datetime "due_date", null: false
    t.integer "reviews_count", default: 0, null: false, unsigned: true
    t.integer "lapses_count", default: 0, null: false, unsigned: true
    t.datetime "last_review_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "due_date"], name: "index_srs_cards_on_user_id_and_due_date"
    t.index ["user_id", "interval"], name: "index_srs_cards_on_user_id_and_interval"
    t.index ["user_id", "kanji"], name: "index_srs_cards_on_user_id_and_kanji", unique: true
    t.index ["user_id", "state"], name: "index_srs_cards_on_user_id_and_state"
    t.index ["user_id"], name: "index_srs_cards_on_user_id"
  end

  create_table "tango_lesson_progresses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "book_id", limit: 50, null: false
    t.string "lesson_id", limit: 100, null: false
    t.boolean "completed", default: false, null: false
    t.integer "known_count", default: 0, null: false, unsigned: true
    t.integer "total_count", default: 0, null: false, unsigned: true
    t.datetime "last_studied_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "book_id", "lesson_id"], name: "idx_tango_progress_unique", unique: true
    t.index ["user_id", "book_id"], name: "idx_tango_progress_user_book"
    t.index ["user_id"], name: "index_tango_lesson_progresses_on_user_id"
  end

  create_table "user_notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "body"
    t.string "link"
    t.string "notification_type", default: "feedback", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "feedback_id"
    t.string "created_by", default: "system", null: false
    t.index ["feedback_id"], name: "index_user_notifications_on_feedback_id"
    t.index ["user_id", "read"], name: "index_user_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "user_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "learn_mode", limit: 20, default: "kanji", null: false
    t.string "kanji_font", limit: 50, default: "zen-maru-gothic", null: false
    t.string "primary_color", limit: 50, default: "205 100% 50%", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "uid", limit: 128, null: false
    t.string "email", null: false
    t.string "display_name"
    t.text "photo_url"
    t.string "provider", limit: 50, default: "google", null: false
    t.boolean "is_premium", default: false, null: false
    t.datetime "premium_until"
    t.string "jti", null: false
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_banned", default: false, null: false
    t.string "banned_reason", limit: 500
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "chat_rooms", "users"
  add_foreign_key "contacts", "users"
  add_foreign_key "custom_vocab_items", "users"
  add_foreign_key "daily_request_stats", "users", on_delete: :cascade
  add_foreign_key "feedbacks", "feedbacks", column: "parent_id", on_delete: :cascade
  add_foreign_key "feedbacks", "users"
  add_foreign_key "jlpt_test_results", "users"
  add_foreign_key "login_activities", "users", on_delete: :cascade
  add_foreign_key "review_logs", "users"
  add_foreign_key "roadmap_day_progresses", "users"
  add_foreign_key "srs_cards", "users"
  add_foreign_key "tango_lesson_progresses", "users"
  add_foreign_key "user_notifications", "feedbacks", on_delete: :cascade
  add_foreign_key "user_notifications", "users"
  add_foreign_key "user_settings", "users"
end
