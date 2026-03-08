# frozen_string_literal: true

class CustomRoadmap < ApplicationRecord
  belongs_to :user
  has_many :custom_roadmap_day_progresses, dependent: :destroy

  attribute :kanji_list, default: []

  validates :name, presence: true, length: { maximum: 100 }
  validates :kanji_per_day, presence: true, numericality: { only_integer: true, in: 1..50 }
  validates :kanji_list, presence: true
  validate :kanji_list_not_empty

  scope :ordered, -> { order(created_at: :desc) }

  def total_days
    return 0 if kanji_list.blank?

    (kanji_list.length.to_f / kanji_per_day).ceil
  end

  def kanji_for_day(day)
    start_index = (day - 1) * kanji_per_day
    kanji_list[start_index, kanji_per_day] || []
  end

  def self.ransackable_attributes _auth_object = nil
    %w[name created_at]
  end

  private

  def kanji_list_not_empty
    errors.add(:kanji_list, "không được để trống") if kanji_list.blank?
  end
end
