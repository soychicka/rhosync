class AddPinToDevices < ActiveRecord::Migration
  def self.up
    add_column :devices, :pin, :string
    add_column :devices, :host, :string
    add_column :devices, :serverport, :string
    add_column :devices, :deviceport, :string
  end

  def self.down
    remove_column :devices, :pin
    remove_column :devices, :host
    remove_column :devices, :serverport
    remove_column :devices, :deviceport
  end
end
