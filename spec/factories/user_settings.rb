FactoryBot.define do
  factory :user_setting do
    user
    learn_mode { "kanji" }
    kanji_font { "zen-maru-gothic" }
    primary_color { "205 100% 50%" }
  end
end
