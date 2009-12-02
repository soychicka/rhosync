require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "User" do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  
  it "should create user with fields" do
    fields = {
      :login => 'testuser',
      :email => 'testuser@example.com'
    }
    @u = User.create(fields)
    @u.id.should == fields[:login]

    @u1 = User.with_key(fields[:login])
    @u1.id.should == @u.id
    @u1.login.should == fields[:login]
    @u1.email.should == fields[:email]
  end
  
  it "should authenticate with proper credentials" do
    fields = {
      :login => 'testuser',
      :email => 'testuser@example.com'
    }
    @u = User.create(fields)
    @u.password = 'testpass'
    @u1 = User.authenticate(fields[:login],'testpass')
    @u1.should_not be_nil
    @u1.login.should == fields[:login]
    @u1.email.should == fields[:email]
  end
  
  it "should fail to authenticate with invalid credentials" do
    fields = {
      :login => 'testuser',
      :email => 'testuser@example.com'
    }
    @u = User.create(fields)
    @u.password = 'testpass'
    User.authenticate(fields[:login],'wrongpass').should be_nil
  end
  
  it "should fail to authenticate with nil user" do
    User.authenticate('niluser','doesnotmatter').should be_nil
  end
end