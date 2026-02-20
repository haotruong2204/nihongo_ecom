# frozen_string_literal: true

require "rails_helper"

RSpec.describe TangoLessonProgress, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:tango_lesson_progress) }

    it { is_expected.to validate_presence_of(:book_id) }
    it { is_expected.to validate_presence_of(:lesson_id) }
    it { is_expected.to validate_uniqueness_of(:lesson_id).scoped_to(%i[user_id book_id]) }
  end

  describe "scopes" do
    let(:user) { create(:user) }

    describe ".for_book" do
      it "filters by book_id" do
        n5 = create(:tango_lesson_progress, user: user, book_id: "tango-n5")
        create(:tango_lesson_progress, user: user, book_id: "mimi-n3")

        expect(described_class.for_book("tango-n5")).to contain_exactly(n5)
      end
    end

    describe ".completed" do
      it "returns only completed lessons" do
        done = create(:tango_lesson_progress, :completed, user: user)
        create(:tango_lesson_progress, user: user, completed: false)

        expect(described_class.completed).to contain_exactly(done)
      end
    end
  end
end
