class FixObjectIndex < ActiveRecord::Migration
  def self.up
    add_index :client_maps, :dirty, :name=>'by_dirty'
    add_index :object_values, :object, :name=>'by_obj'
  end

  def self.down
    remove_index :client_maps, :name=>'by_dirty'
    remove_index :object_values, :name=>'by_obj'
  end
end
