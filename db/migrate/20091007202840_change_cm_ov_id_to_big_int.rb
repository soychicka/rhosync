class ChangeCmOvIdToBigInt < ActiveRecord::Migration
  def self.up
    change_column :client_maps, :object_value_id, :bigint
  end

  def self.down
    change_column :client_maps, :object_value_id, :integer
  end
end
