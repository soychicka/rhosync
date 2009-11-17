require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'
include RhosyncStore

describe "RhosyncClientSync" do

  it_should_behave_like  "RhosyncStoreDataHelper"
  
  before(:each) do
    @store = Store.new
    @store.db.flushdb
    @client = Client.new(@store,@source,@user,'cd')
  end
  
  it "should return diffs between master documents and client documents limited by page size" do
    @store.put_data('md',@source,@user,@data).should == true
    @store.get_data('md',@source,@user).should == @data

    @expected = {'1'=>@product1,'2'=>@product2}
    @client.put_page('md',2).should == @expected
    @client.get_page.should == @expected      
  end
  
  it "appends diff to the client document" do
    @cd = {'3'=>@product3}  
    @store.put_data('cd',@source,@user,@cd)
    @store.get_data('cd',@source,@user).should == @cd

    @page = {'1'=>@product1,'2'=>@product2}
    @expected = {'1'=>@product1,'2'=>@product2,'3'=>@product3}

    @store.put_data('cd',@source,@user,@page,true).should == true
    @store.get_data('cd',@source,@user).should == @expected
  end
    
  it "should return deleted objects in the client document" do
    @store.put_data('md',@source,@user,@data).should == true
    @store.get_data('md',@source,@user).should == @data

    @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
    @store.put_data('cd',@source,@user,@cd)
    @store.get_data('cd',@source,@user).should == @cd
      
    @expected = {'D'=>{'4'=>'name,brand,price'}}
    @client.put_deleted_page('md',2).should == @expected
  end  
      
end