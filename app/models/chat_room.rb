# frozen_string_literal: true

class ChatRoom < ApplicationRecord
  belongs_to :user, optional: true

  validates :uid, presence: true, uniqueness: true

  before_validation :link_user, on: :create

  scope :by_status, ->(status) { where(status: status) }

  def self.ransackable_attributes _auth_object = nil
    %w[uid status chat_banned created_at]
  end

  private

  def link_user
    self.user ||= User.find_by(uid: uid)
  end
end
