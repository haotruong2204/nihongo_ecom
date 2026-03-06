# frozen_string_literal: true

class VocabSetSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :items, :position, :created_at, :updated_at

  attribute :items_count do |set|
    (set.items || []).size
  end
end
