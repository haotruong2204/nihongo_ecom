# frozen_string_literal: true

class User < ApplicationRecord
  extend OauthCommon
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :jwt_authenticatable, jwt_revocation_strategy: self

  GOOGLE_API_INFO_ENDPOINT = "https://www.googleapis.com/oauth2/v3/userinfo"

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

  def self.ransackable_attributes(_auth_object = nil)
    %w[email display_name provider is_premium is_banned created_at]
  end

  def premium?
    is_premium && (premium_until.nil? || premium_until > Time.current)
  end

  def banned?
    is_banned
  end

  private

  def generate_jti
    self.jti ||= SecureRandom.uuid
  end
end
