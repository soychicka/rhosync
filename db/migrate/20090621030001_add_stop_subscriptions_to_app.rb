class AddStopSubscriptionsToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :stop_subscriptions, :boolean
  end

  def self.down
    remove_column :apps, :stop_subscriptions
  end
end
