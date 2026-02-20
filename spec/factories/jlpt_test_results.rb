FactoryBot.define do
  factory :jlpt_test_result do
    user
    level { "N5" }
    correct_count { 28 }
    incorrect_count { 7 }
    total_questions { 35 }
    time_used { 1200 }
    time_limit { 1800 }
    passed { true }
    sections { [{ name: "漢字", correct: 10, total: 12 }, { name: "語彙", correct: 18, total: 23 }] }
    taken_at { Time.current }

    trait :failed do
      correct_count { 10 }
      incorrect_count { 25 }
      passed { false }
    end
  end
end
