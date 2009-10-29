class RemoveNotifiesTasks < ActiveRecord::Migration
  def self.up
    drop_table :source_notifies
    drop_table :synctasks
  end

  def self.down
  end
end
