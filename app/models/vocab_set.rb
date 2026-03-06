# frozen_string_literal: true

class VocabSet < ApplicationRecord
  belongs_to :user

  attribute :items, default: []

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :created_at) }

  def self.ransackable_attributes _auth_object = nil
    %w[name position created_at]
  end
end
