# frozen_string_literal: true

class PageView < ApplicationRecord
  belongs_to :user

  scope :recent, -> { order(last_visited_at: :desc) }

  def self.ransackable_attributes _auth_object = nil
    %w[user_id url view_count last_visited_at]
  end

  def self.ransackable_associations _auth_object = nil
    %w[user]
  end
end
