# frozen_string_literal: true

class FeedbackSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :email, :text, :display, :status, :admin_reply, :replied_at,
             :parent_id, :context_type, :context_id, :context_label,
             :created_at, :updated_at

  belongs_to :user, serializer: UserSerializer
  has_many :replies, serializer: FeedbackSerializer
end
