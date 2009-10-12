class ChangeOvIdToBigint < ActiveRecord::Migration
  def self.up
    create_table "object_values", :id => false, :force => true do |t| 
      t.integer  "source_id"
      t.string   "object"
      t.string   "attrib"
      t.text     "value"
      t.integer  "pending_id", :limit => 8
      t.string   "update_type"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "blob_file_name"
      t.string   "blob_content_type"
      t.integer  "blob_file_size"
      t.string   "attrib_type"
    end
    execute "ALTER TABLE object_values ADD `id` bigint(20) AUTO_INCREMENT PRIMARY KEY"
  end

  def self.down
  end
end
