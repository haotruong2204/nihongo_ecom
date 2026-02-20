# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:srs_cards).dependent(:destroy) }
    it { is_expected.to have_many(:review_logs).dependent(:destroy) }
    it { is_expected.to have_many(:roadmap_day_progresses).dependent(:destroy) }
    it { is_expected.to have_many(:custom_vocab_items).dependent(:destroy) }
    it { is_expected.to have_one(:user_setting).dependent(:destroy) }
    it { is_expected.to have_many(:feedbacks).dependent(:nullify) }
    it { is_expected.to have_many(:contacts).dependent(:nullify) }
    it { is_expected.to have_many(:tango_lesson_progresses).dependent(:destroy) }
    it { is_expected.to have_many(:jlpt_test_results).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:uid) }
    it { is_expected.to validate_uniqueness_of(:uid) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:jti) }
    it { is_expected.to validate_uniqueness_of(:jti) }
  end

  describe "callbacks" do
    it "generates jti before validation on create" do
      user = build(:user, jti: nil)
      user.valid?
      expect(user.jti).to be_present
    end
  end

  describe "#premium?" do
    it "returns false when not premium" do
      user = build(:user, is_premium: false)
      expect(user.premium?).to be false
    end

    it "returns true for lifetime premium" do
      user = build(:user, is_premium: true, premium_until: nil)
      expect(user.premium?).to be true
    end

    it "returns true when premium_until is in the future" do
      user = build(:user, is_premium: true, premium_until: 1.month.from_now)
      expect(user.premium?).to be true
    end

    it "returns false when premium_until has passed" do
      user = build(:user, is_premium: true, premium_until: 1.day.ago)
      expect(user.premium?).to be false
    end
  end
end
