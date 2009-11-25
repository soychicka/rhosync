require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'
include RhosyncStore

describe "ClientStore" do

  it_should_behave_like  "RhosyncStoreDataHelper"
  
  before(:each) do
    @store = Store.new
    @store.db.flushdb
    @client = ClientStore.new(@store,@cdoc)
  end
  
  it "should return diffs between master documents and client documents limited by page size" do
    @store.put_data(@mdoc,@data).should == true
    @store.get_data(@mdoc).should == @data

    @expected = {'1'=>@product1,'2'=>@product2}
    @client.put_page(@mdoc,2).should == @expected
    @client.get_page.should == @expected      
  end
  
  it "appends diff to the client document" do
    @cd = {'3'=>@product3}  
    @store.put_data(@cdoc,@cd)
    @store.get_data(@cdoc).should == @cd

    @page = {'1'=>@product1,'2'=>@product2}
    @expected = {'1'=>@product1,'2'=>@product2,'3'=>@product3}

    @store.put_data(@cdoc,@page,true).should == true
    @store.get_data(@cdoc).should == @expected
  end
    
  it "should return deleted objects in the client document" do
    @store.put_data(@mdoc,@data).should == true
    @store.get_data(@mdoc).should == @data

    @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
    @store.put_data(@cdoc,@cd)
    @store.get_data(@cdoc).should == @cd
      
    @expected = {'4'=>@product4}
    @client.put_deleted_page(@mdoc,2).should == @expected
    @client.get_deleted_page.should == @expected
  end  
            
  it "should delete objects from client document" do
    @store.put_data(@mdoc,@data).should == true
    @store.get_data(@mdoc).should == @data
  
    @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
    @store.put_data(@cdoc,@cd)
    @store.get_data(@cdoc).should == @cd
  
    @deleted = @client.put_deleted_page(@mdoc,2)
    @store.delete_data(@cdoc,@deleted).should == true
    @store.get_data(@cdoc).should == @data 
  end
  
end