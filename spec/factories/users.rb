FactoryBot.define do
  factory :user do
    sequence(:uid) { |n| "firebase_uid_#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    display_name { "Test User" }
    provider { "google" }
    jti { SecureRandom.uuid }
  end
end
