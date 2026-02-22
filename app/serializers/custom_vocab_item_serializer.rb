# frozen_string_literal: true

class CustomVocabItemSerializer
  include JSONAPI::Serializer

  attributes :id, :word, :reading, :hanviet, :meaning, :position, :created_at, :updated_at
end
