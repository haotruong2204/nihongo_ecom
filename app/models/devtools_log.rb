# frozen_string_literal: true

class DevtoolsLog < ApplicationRecord
  belongs_to :user, optional: true

  scope :recent, -> { order(last_detected_at: :desc) }

  def self.ransackable_attributes _auth_object = nil
    %w[ip_address email open_count last_detected_at created_at]
  end

  def self.ransackable_associations _auth_object = nil
    %w[user]
  end
end
