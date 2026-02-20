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

ActiveRecord::Schema[8.0].define(version: 2026_02_18_090010) do
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
    t.index ["created_at"], name: "index_feedbacks_on_created_at"
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

  create_table "review_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kanji", limit: 10, null: false
    t.integer "rating", limit: 1, null: false
    t.integer "interval_before", default: 0, null: false, unsigned: true
    t.integer "interval_after", default: 0, null: false, unsigned: true
    t.datetime "reviewed_at", null: false
    t.datetime "created_at", null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "contacts", "users"
  add_foreign_key "custom_vocab_items", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "jlpt_test_results", "users"
  add_foreign_key "review_logs", "users"
  add_foreign_key "roadmap_day_progresses", "users"
  add_foreign_key "srs_cards", "users"
  add_foreign_key "tango_lesson_progresses", "users"
  add_foreign_key "user_settings", "users"
end
