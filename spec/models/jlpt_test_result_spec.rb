# frozen_string_literal: true

require "rails_helper"

RSpec.describe JlptTestResult, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:level) }
    it { is_expected.to validate_inclusion_of(:level).in_array(%w[N5 N4 N3 N2 N1]) }
    it { is_expected.to validate_presence_of(:correct_count) }
    it { is_expected.to validate_presence_of(:incorrect_count) }
    it { is_expected.to validate_presence_of(:total_questions) }
    it { is_expected.to validate_presence_of(:time_used) }
    it { is_expected.to validate_presence_of(:time_limit) }
    it { is_expected.to validate_presence_of(:taken_at) }
    it { is_expected.to validate_presence_of(:sections) }
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".for_level" do
      it "filters by JLPT level" do
        n5 = create(:jlpt_test_result, user: user, level: "N5")
        create(:jlpt_test_result, user: user, level: "N3")

        expect(described_class.for_level("N5")).to contain_exactly(n5)
      end
    end

    describe ".passed" do
      it "returns only passed results" do
        passed = create(:jlpt_test_result, user: user, passed: true)
        create(:jlpt_test_result, :failed, user: user)

        expect(described_class.passed).to contain_exactly(passed)
      end
    end
  end
end
