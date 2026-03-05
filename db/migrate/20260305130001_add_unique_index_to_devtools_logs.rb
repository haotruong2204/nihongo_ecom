# frozen_string_literal: true

class AddUniqueIndexToDevtoolsLogs < ActiveRecord::Migration[8.0]
  def change
    remove_index :devtools_logs, :ip_address
    add_index :devtools_logs, [:ip_address, :user_id], unique: true, name: "idx_devtools_logs_ip_user"
    add_index :devtools_logs, :ip_address, name: "idx_devtools_logs_ip"
  end
end
