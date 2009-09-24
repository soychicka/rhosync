class RemoveSessionFromClient < ActiveRecord::Migration
  def self.up
    remove_column :clients, :session
  end

  def self.down
    add_column :clients, :session, :string
  end
end
