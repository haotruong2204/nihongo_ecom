# frozen_string_literal: true

class QuickReplySerializer
  include JSONAPI::Serializer

  attributes :id, :title, :content, :image_url, :position, :active, :created_at, :updated_at
end
