class AddAttributesToDevice < ActiveRecord::Migration
  def self.up
    add_column :devices, :type, :string
    add_column :devices, :carrier, :string
    add_column :devices, :manufacturer, :string
    add_column :devices, :model, :string
  end

  def self.down
    remove_column :devices, :model
    remove_column :devices, :manufacturer
    remove_column :devices, :carrier
    remove_column :devices, :type
  end
end
