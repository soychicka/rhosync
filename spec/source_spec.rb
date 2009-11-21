require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Source" do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  
  it "should create source with fields" do
    fields = {
      :name => 'TestSource',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass'
    }
    @s = Source.create(fields)
    @s.name.should == fields[:name]
    @s.url.should == fields[:url]
    @s.login.should == fields[:login]
    @s.password.should == fields[:password]
    @s.app.should be_nil
    @s.pollinterval.should == 300
    @s.priority.should == 3
    @s.callback_url.should be_nil

    @s1 = Source.with_key(@s.id)
    @s1.name.should == @s.name
    @s1.url.should == @s.url
    @s1.login.should == @s.login
    @s1.password.should == @s.password
    @s1.app.should be_nil
    @s1.pollinterval.should == 300
    @s1.priority.should == 3
    @s1.callback_url.should be_nil
  end
end