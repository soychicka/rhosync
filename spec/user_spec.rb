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
      :email => 'testuser@example.com',
      :password => 'testpass'
    }
    @u = User.create(fields)
    @u.id.should == 1

    @u1 = User.with_key(1)
    @u1.id.should == @u.id
    @u1.login.should == fields[:login]
    @u1.email.should == fields[:email]
    @u1.password.should == fields[:password]
  end
end