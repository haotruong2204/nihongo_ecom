FactoryBot.define do
  factory :tango_lesson_progress do
    user
    book_id { "tango-n5" }
    sequence(:lesson_id) { |n| "lesson#{n}" }
    completed { false }
    known_count { 0 }
    total_count { 20 }

    trait :completed do
      completed { true }
      known_count { 20 }
      last_studied_at { Time.current }
    end
  end
end
