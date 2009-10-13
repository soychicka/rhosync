class AddSrcUserUTypeIndexToOv < ActiveRecord::Migration
  def self.up
    add_index :object_values, [:update_type,:source_id,:user_id], :name=>'by_ut_s_u'
    add_index :object_values, [:update_type,:source_id], :name=>'by_ut_s'
  end

  def self.down
    remove_index :object_values, :name=>'by_ut_s_u'
    remove_index :object_values, :name=>'by_ut_s'
  end
end
