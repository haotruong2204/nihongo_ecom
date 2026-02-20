# frozen_string_literal: true

require "rails_helper"

RSpec.describe RoadmapDayProgress, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:roadmap_day_progress) }

    it { is_expected.to validate_presence_of(:day) }
    it { is_expected.to validate_uniqueness_of(:day).scoped_to(:user_id) }
    it { is_expected.to validate_presence_of(:kanji_learned) }
    it { is_expected.to validate_presence_of(:completed_at) }

    it "validates day is between 1 and 250" do
      expect(build(:roadmap_day_progress, day: 0)).not_to be_valid
      expect(build(:roadmap_day_progress, day: 251)).not_to be_valid
      expect(build(:roadmap_day_progress, day: 1)).to be_valid
      expect(build(:roadmap_day_progress, day: 250)).to be_valid
    end
  end
end
