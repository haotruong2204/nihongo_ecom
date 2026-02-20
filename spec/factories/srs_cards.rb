FactoryBot.define do
  factory :srs_card do
    user
    sequence(:kanji) { |n| %w[漢 字 学 生 日 本 語 読 書 力][n % 10] }
    state { :new_card }
    ease { 2.50 }
    interval { 0 }
    due_date { Time.current }
    reviews_count { 0 }
    lapses_count { 0 }

    trait :learning do
      state { :learning }
      interval { 1 }
    end

    trait :review do
      state { :review }
      ease { 2.50 }
      interval { 10 }
      due_date { 10.days.from_now }
    end

    trait :mature do
      state { :review }
      interval { 30 }
      due_date { 30.days.from_now }
    end

    trait :due do
      due_date { 1.hour.ago }
    end
  end
end
