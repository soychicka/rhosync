class CreateClientTempObjects < ActiveRecord::Migration
  def self.up
    create_table :client_temp_objects do |t|
      t.string :client_id
      t.string :objectid
      t.string :temp_objectid
      t.string :token
    end
  end

  def self.down
    drop_table :client_temp_objects
  end
end
