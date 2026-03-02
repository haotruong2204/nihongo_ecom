# frozen_string_literal: true

class LoginActivity < ApplicationRecord
  belongs_to :user

  scope :recent, -> { order(created_at: :desc) }
  scope :conflicts, -> { where(session_conflict: true) }

  def self.ransackable_attributes _auth_object = nil
    %w[ip_address device_info session_conflict country city created_at]
  end

  def self.ransackable_associations _auth_object = nil
    %w[user]
  end
end
