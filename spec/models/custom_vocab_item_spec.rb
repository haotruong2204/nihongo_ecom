# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomVocabItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:custom_vocab_item) }

    it { is_expected.to validate_presence_of(:word) }
    it { is_expected.to validate_uniqueness_of(:word).scoped_to(:user_id) }
    it { is_expected.to validate_presence_of(:reading) }
    it { is_expected.to validate_presence_of(:meaning) }
    it { is_expected.to validate_length_of(:meaning).is_at_most(500) }
  end

  describe "scopes" do
    it "orders by position" do
      user = create(:user)
      third = create(:custom_vocab_item, user: user, position: 3)
      first = create(:custom_vocab_item, user: user, position: 1)
      second = create(:custom_vocab_item, user: user, position: 2)

      expect(described_class.ordered).to eq([first, second, third])
    end
  end
end
