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
    @s.app.name.should be_nil
    @s.pollinterval.should == 300
    @s.priority.should == 3
    @s.callback_url.should be_nil

    @s1 = Source.with_key(@s.id)
    @s1.name.should == @s.name
    @s1.url.should == @s.url
    @s1.login.should == @s.login
    @s1.password.should == @s.password
    @s1.app.name.should be_nil
    @s1.pollinterval.should == 300
    @s1.priority.should == 3
    @s1.callback_url.should be_nil
  end
  
  it "should create source with user" do
    u_fields = {
      :login => 'testuser',
      :password => 'testpass'
    }
    @u = User.create(u_fields)
        
    fields = {
      :name => 'TestSource',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :user_id => @u.id
    }
    @s = Source.create(fields)
    @s.user.login.should == u_fields[:login]
    @s.user.password.should == u_fields[:password]
  end
  
  it "should create source with app and document" do
    a_fields = { :name => 'testapp' }
    
    @a = App.create(a_fields)
    
    u_fields = {
      :login => 'testuser',
      :password => 'testpass'
    }
    @u = User.create(u_fields)
        
    fields = {
      :name => 'TestSource',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :user_id => @u.id,
      :app_id => @a.id
    }
    @s = Source.create(fields)
    
    @s.app.name.should == a_fields[:name]
    @s.document.get_key.should == "md:#{fields[:name]}:#{@u.id}"
  end
end