class CreateRefreshes < ActiveRecord::Migration
  def self.up
    create_table :refreshes do |t|
      t.integer :source_id
      t.integer :user_id
      t.datetime :time
    end
    remove_column :sources, :refreshtime
  end

  def self.down
    drop_table :refreshes
    add_column :sources, :refreshtime, :datetime
  end
end
