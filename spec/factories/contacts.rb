FactoryBot.define do
  factory :contact do
    name { "Nguyen Van A" }
    phone { "0901234567" }
    source { "khoa-hoc" }

    trait :with_user do
      user
    end
  end
end
