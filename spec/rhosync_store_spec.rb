require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "RhosyncStore" do
  
  it_should_behave_like  "RhosyncStoreDataHelper"
  
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
  end
  
  it "should add simple data to new set" do
    start = (Time.now.to_f * 1000).to_i
    @store.put_data('doc1',@source,@user,@data).should == true
    @store.get_timestamp('doc1',@source,@user).should >= start
    @store.get_data('doc1',@source,@user).should == @data
  end
  
  it "should replace simple data to existing set" do
    new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
    @store.put_data('doc1',@source,@user,@data).should == true
    @store.put_data('doc1',@source,@user,new_data)
    @store.get_data('doc1',@source,@user).should == new_data
  end
    
  it "should return attributes modified in doc2" do
    @store.put_data('doc1',@source,@user,@data).should == true
    @store.get_data('doc1',@source,@user).should == @data
    
    @product3['price'] = '59.99'
    expected = { '3' => { 'price' => '59.99' } }
    @data1,@data1['1'],@data1['2'],@data1['3'] = {},@product1,@product2,@product3
    
    @store.put_data('doc2',@source,@user,@data1)
    @store.get_data('doc2',@source,@user).should == @data1
    @store.get_diff_data('doc1','doc2',@source,@user).should == expected
  end
  
  it "should return attributes modified and missed in doc2" do
    @store.put_data('doc1',@source,@user,@data).should == true
    @store.get_data('doc1',@source,@user).should == @data
    
    @product2['price'] = '59.99'
    expected = { '2' => { 'price' => '99.99' },'3' => @product3 }
    @data1,@data1['1'],@data1['2'] = {},@product1,@product2
    
    @store.put_data('doc2',@source,@user,@data1)
    @store.get_data('doc2',@source,@user).should == @data1
    @store.get_diff_data('doc2','doc1',@source,@user).should == expected
  end  
end