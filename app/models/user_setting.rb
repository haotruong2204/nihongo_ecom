# frozen_string_literal: true

class UserSetting < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :learn_mode, presence: true, inclusion: { in: %w[kanji hanviet meaning] }
  validates :kanji_font, presence: true
  validates :primary_color, presence: true
end
