FactoryBot.define do
  factory :custom_vocab_item do
    user
    sequence(:word) { |n| "単語#{n}" }
    reading { "たんご" }
    hanviet { "đơn ngữ" }
    meaning { "từ vựng" }
    sequence(:position) { |n| n }
  end
end
