# frozen_string_literal: true

require "rails_helper"

RSpec.describe SrsCard, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:srs_card) }

    it { is_expected.to validate_presence_of(:kanji) }
    it { is_expected.to validate_uniqueness_of(:kanji).scoped_to(:user_id) }
    it { is_expected.to validate_presence_of(:ease) }
    it { is_expected.to validate_presence_of(:due_date) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:state).with_values(new_card: 0, learning: 1, review: 2, relearning: 3) }
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".due_today" do
      it "returns cards with due_date in the past" do
        due = create(:srs_card, user: user, kanji: "漢", due_date: 1.hour.ago)
        create(:srs_card, user: user, kanji: "字", due_date: 1.day.from_now)

        expect(described_class.due_today).to contain_exactly(due)
      end
    end

    describe ".young / .mature" do
      it "separates review cards by interval" do
        young = create(:srs_card, :review, user: user, kanji: "学", interval: 10)
        mature = create(:srs_card, :mature, user: user, kanji: "生")

        expect(described_class.young).to contain_exactly(young)
        expect(described_class.mature).to contain_exactly(mature)
      end
    end
  end
end
