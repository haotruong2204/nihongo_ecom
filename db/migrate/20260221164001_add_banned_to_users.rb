class AddBannedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_banned, :boolean, null: false, default: false
    add_column :users, :banned_reason, :string, limit: 500
  end
end
