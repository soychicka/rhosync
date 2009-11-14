require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'
include RhosyncStore

describe "RhosyncClientSync" do

  it_should_behave_like  "RhosyncStoreDataHelper"
  
  before(:each) do
    @store = Store.new
    @store.db.flushdb
    @client = Client.new(@store,@source,@user,'cid')
  end
  
  it "should return diffs between md and client" do
    @store.put_data('md',@source,@user,@data).should == true
    @store.get_data('md',@source,@user).should == @data

    @cd = {}    
    @store.put_data('cd',@source,@user,@cd)
    @store.get_data('cd',@source,@user).should == @cd

    @expected = {'1'=>@product1,'2'=>@product2}
    @client.put_page('md',2).should == @expected
    @client.get_page.should == @expected      
  end
  
  it "should set md and cd documents states and return sync-page after first client sync request" do
    @store.put_data('md',@source,@user,@data).should == true
    @store.get_data('md',@source,@user).should == @data
    
    @cd = {}    
    @store.put_data('cd',@source,@user,@cd)
    @store.get_data('cd',@source,@user).should == @cd
    
    @store.get_diff_data('cd','md',@source,@user).should == @data
  end
    
end