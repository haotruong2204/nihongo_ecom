# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewLog, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:kanji) }
    it { is_expected.to validate_presence_of(:rating) }
    it { is_expected.to validate_presence_of(:reviewed_at) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:rating).with_values(again: 1, hard: 2, good: 3, easy: 4) }
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".on_date" do
      it "returns logs for a specific date" do
        today_log = create(:review_log, user: user, reviewed_at: Time.current)
        create(:review_log, user: user, kanji: "字", reviewed_at: 2.days.ago)

        expect(described_class.on_date(Date.current)).to contain_exactly(today_log)
      end
    end

    describe ".for_kanji" do
      it "filters by kanji" do
        log = create(:review_log, user: user, kanji: "漢")
        create(:review_log, user: user, kanji: "字")

        expect(described_class.for_kanji("漢")).to contain_exactly(log)
      end
    end
  end
end
