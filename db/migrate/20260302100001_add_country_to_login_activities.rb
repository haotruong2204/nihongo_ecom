# frozen_string_literal: true

class AddCountryToLoginActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :login_activities, :country, :string, limit: 100
  end
end
