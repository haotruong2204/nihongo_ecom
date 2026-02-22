# frozen_string_literal: true

class UserSettingSerializer
  include JSONAPI::Serializer

  attributes :id, :learn_mode, :kanji_font, :primary_color, :created_at, :updated_at
end
