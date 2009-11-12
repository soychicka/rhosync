$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "RhosyncStore" do
  before(:each) do
    @source = 'Product'
    @user = 5
    
    @product1 = {
      'name' => 'iPhone',
      'brand' => 'Apple',
      'price' => '199.99'
    }
    
    @product2 = {
      'name' => 'G2',
      'brand' => 'Android',
      'price' => '99.99'
    }
    
    @data,@data['1'],@data['2'] = {},@product1,@product2
    
    @sync_store = RhosyncStore.new
    @sync_store.db.flushdb
  end
  
  it "should add simple data to new set" do
    @sync_store.put_data(@source,@user,@data).should == true
    @sync_store.get_data(@source,@user).should == @data
  end
  
  it "should replace simple data to existing set" do
    new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
    @sync_store.put_data(@source,@user,@data).should == true
    @sync_store.put_data(@source,@user,new_data)
    @sync_store.get_data(@source,@user).should == new_data
  end
  
  it "should compute backend shadow copy" do
    
  end
  
  # 
  # it "should compute intersect between two sets" do
  #   
  # end
  # 
  # it "should retrieve all keys for a set" do
  #   
  # end
  
end