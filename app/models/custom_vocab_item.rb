# frozen_string_literal: true

class CustomVocabItem < ApplicationRecord
  belongs_to :user

  validates :word, presence: true, uniqueness: { scope: :user_id }
  validates :reading, presence: true
  validates :meaning, presence: true, length: { maximum: 500 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position) }

  def self.ransackable_attributes _auth_object = nil
    %w[word reading position created_at]
  end
end
