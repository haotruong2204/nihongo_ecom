# frozen_string_literal: true

class AddCityToLoginActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :login_activities, :city, :string, limit: 100
  end
end
