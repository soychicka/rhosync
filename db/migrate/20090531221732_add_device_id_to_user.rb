class AddDeviceIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :device_id, :integer
  end

  def self.down
    remove_column :users, :device_id
  end
end
