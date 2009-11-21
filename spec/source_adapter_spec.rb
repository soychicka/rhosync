require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "SourceAdapter" do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
    
    @path = File.join(File.dirname(__FILE__),'adapters')
    RhosyncStore.set_adapter_path(@path)
    
    @fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass'
    }
    @src = Source.create(@fields)
  end
  
  it "should create SourceAdapter with source" do
    @sa = SourceAdapter.create(@src)
    @sa.class.name.should == @fields[:name]
  end
  
  it "should fail to create SourceAdapter" do
    @fields[:name] = 'Broken'
    broken_source = Source.create(@fields)
    lambda { SourceAdapter.create(broken_source) }.should raise_error(Exception)
  end
end