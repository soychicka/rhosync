class AddCallbackUrlToSources < ActiveRecord::Migration
  def self.up
    add_column :sources, :callback_url, :string
  end

  def self.down
    remove_column :sources, :callback_url
  end
end
