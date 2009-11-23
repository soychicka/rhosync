require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "App" do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  
  it "should create app with fields" do
    fields = { :name => 'myapp' }
    @a = App.create(fields)
    @a.id.should == 1

    @a1 = App.with_key(1)
    @a1.id.should == @a.id
    @a1.name.should == fields[:name]
  end
  
  it "should create app with store" do
    fields = { :name => 'myapptwo' }
    @a = App.create(fields)
    @a.name.should == fields[:name]
    @a.store.db.class.should == Redis 
  end
end