class AddDeviceColumnsToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :device_type, :string
    add_column :clients, :carrier, :string
    add_column :clients, :manufacturer, :string
    add_column :clients, :model, :string
    add_column :clients, :pin, :string
    add_column :clients, :host, :string
    add_column :clients, :serverport, :string
    add_column :clients, :deviceport, :string
  end

  def self.down
    remove_column :clients, :model
    remove_column :clients, :manufacturer
    remove_column :clients, :carrier
    remove_column :clients, :device_type
    remove_column :clients, :pin
    remove_column :clients, :host
    remove_column :clients, :serverport
    remove_column :clients, :deviceport
  end
end
