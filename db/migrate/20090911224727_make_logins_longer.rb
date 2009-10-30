class MakeLoginsLonger < ActiveRecord::Migration
  def self.up
    change_column :users, :login, :string, :limit => 255
  end

  def self.down
    change_column :users, :login, :string, :limit => 40
  end
end
