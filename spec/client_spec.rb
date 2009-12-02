require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Client" do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  
  it "should create client with fields" do
    fields = { :device_type => 'iphone' }
    @c = Client.create(fields)
    @c.id.should == 1
  end
  
  it "should create client with user_id" do
    fields = { :device_type => 'iphone', :user_id => 'testuser' }
    @c = Client.create(fields)
    @c.id.should == 1
    @c.user_id.should == fields[:user_id] 
  end
end