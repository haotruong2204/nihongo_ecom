# frozen_string_literal: true

class AddLocationToDevtoolsLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devtools_logs, :country, :string, limit: 100
    add_column :devtools_logs, :city, :string, limit: 100
  end
end
