FactoryBot.define do
  factory :review_log do
    user
    kanji { "漢" }
    rating { :good }
    interval_before { 0 }
    interval_after { 1 }
    reviewed_at { Time.current }
  end
end
