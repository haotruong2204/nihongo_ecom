# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserSetting, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:user_setting) }

    it { is_expected.to validate_uniqueness_of(:user_id) }
    it { is_expected.to validate_presence_of(:learn_mode) }
    it { is_expected.to validate_inclusion_of(:learn_mode).in_array(%w[kanji hanviet meaning]) }
    it { is_expected.to validate_presence_of(:kanji_font) }
    it { is_expected.to validate_presence_of(:primary_color) }
  end
end
