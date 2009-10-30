class AddSrcUserUTypeIndexToOv < ActiveRecord::Migration
  def self.up
    add_index :object_values, [:update_type], :name=>'by_ut'
    add_index :object_values, [:source_id], :name=>'by_s'
    add_index :object_values, [:user_id], :name=>'by_u'
  end

  def self.down
    remove_index :object_values, :name=>'by_ut'
    remove_index :object_values, :name=>'by_s'
    remove_index :object_values, :name=>'by_u'
  end
end
