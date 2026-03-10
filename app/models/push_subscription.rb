# frozen_string_literal: true

class PushSubscription < ApplicationRecord
  belongs_to :user

  before_validation :set_endpoint_digest

  validates :endpoint, :p256dh_key, :auth_key, presence: true
  validates :endpoint_digest, uniqueness: true

  private

  def set_endpoint_digest
    self.endpoint_digest = Digest::SHA256.hexdigest(endpoint.to_s)
  end
end
