# frozen_string_literal: true

class PublicFeedbackSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :email, :text, :status, :admin_reply, :replied_at,
             :parent_id, :context_type, :context_id, :context_label,
             :created_at, :updated_at

  has_many :displayed_replies, serializer: PublicFeedbackSerializer
end
