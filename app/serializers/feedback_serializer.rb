# frozen_string_literal: true

class FeedbackSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :email, :text, :display, :status, :admin_reply, :replied_at, :created_at, :updated_at
end
