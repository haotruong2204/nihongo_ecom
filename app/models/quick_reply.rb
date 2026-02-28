# frozen_string_literal: true

class QuickReply < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[title active position created_at]
  end
end
