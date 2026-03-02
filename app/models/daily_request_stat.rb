# frozen_string_literal: true

class DailyRequestStat < ApplicationRecord
  belongs_to :user

  scope :flagged, -> { where(flagged: true) }
  scope :for_date, ->(date) { where(date: date) }
  scope :recent, -> { order(date: :desc) }

  def self.ransackable_attributes _auth_object = nil
    %w[user_id date total_requests flagged flag_reason created_at]
  end

  def self.ransackable_associations _auth_object = nil
    %w[user]
  end
end
