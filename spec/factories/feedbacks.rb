FactoryBot.define do
  factory :feedback do
    user
    text { "App rất hay, cảm ơn!" }
    display { false }
    status { :pending }

    trait :displayed do
      display { true }
    end

    trait :anonymous do
      user { nil }
      email { "anon@example.com" }
    end
  end
end
