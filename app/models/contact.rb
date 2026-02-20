# frozen_string_literal: true

class Contact < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :phone, presence: true, length: { maximum: 50 }

  scope :recent, -> { order(created_at: :desc) }
end
