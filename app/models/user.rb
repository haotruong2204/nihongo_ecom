# frozen_string_literal: true

class User < ApplicationRecord
  has_many :srs_cards, dependent: :destroy
  has_many :review_logs, dependent: :destroy
  has_many :roadmap_day_progresses, dependent: :destroy
  has_many :custom_vocab_items, dependent: :destroy
  has_one :user_setting, dependent: :destroy
  has_many :feedbacks, dependent: :nullify
  has_many :contacts, dependent: :nullify
  has_many :tango_lesson_progresses, dependent: :destroy
  has_many :jlpt_test_results, dependent: :destroy

  validates :uid, presence: true, uniqueness: true, length: { maximum: 128 }
  validates :email, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :provider, presence: true
  validates :jti, presence: true, uniqueness: true

  before_validation :generate_jti, on: :create

  def premium?
    is_premium && (premium_until.nil? || premium_until > Time.current)
  end

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
end
