# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feedback, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:text) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, reviewed: 1, done: 2, rejected: 3) }
  end

  describe "scopes" do
    describe ".displayed" do
      it "returns only displayed feedbacks" do
        displayed = create(:feedback, :displayed)
        create(:feedback, display: false)

        expect(described_class.displayed).to contain_exactly(displayed)
      end
    end
  end
end
