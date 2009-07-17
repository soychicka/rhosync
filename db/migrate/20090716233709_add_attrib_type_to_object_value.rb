class AddAttribTypeToObjectValue < ActiveRecord::Migration
  def self.up
    add_column :object_values, :attrib_type, :string
  end

  def self.down
    drop_column :object_values, :attrib_type
  end
end
