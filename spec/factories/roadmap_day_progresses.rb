FactoryBot.define do
  factory :roadmap_day_progress do
    user
    sequence(:day) { |n| n }
    kanji_learned { %w[漢 字 学] }
    completed_at { Time.current }
  end
end
