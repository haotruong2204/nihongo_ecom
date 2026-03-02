# frozen_string_literal: true

class PageViewSerializer
  include JSONAPI::Serializer

  attributes :id, :user_id, :url, :view_count, :last_visited_at

  belongs_to :user
end
