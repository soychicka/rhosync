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

    @product3 = {
      'name' => 'Fuze',
      'brand' => 'HTC',
      'price' => '299.99'
    }
    
    @product4 = {
      'name' => 'Droid',
      'brand' => 'Android',
      'price' => '249.99'
    }
    
    @data,@data['1'],@data['2'],@data['3'] = {},@product1,@product2,@product3
    
    @sync_store = RhosyncStore.new
    @sync_store.db.flushdb
  end
  
  it "should add simple data to new set" do
    @sync_store.put_data('md',@source,@user,@data).should == true
    @sync_store.get_data('md',@source,@user).should == @data
  end
  
  it "should replace simple data to existing set" do
    new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.put_data('doc1',@source,@user,new_data)
    @sync_store.get_data('doc1',@source,@user).should == new_data
  end
  
  it "should return doc1 objects that were deleted in doc2" do
    @data1,@data1['1'],@data1['2'] = {},@product1,@product2
    expected = ['3']
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.get_data('doc1',@source,@user).should == @data
    @sync_store.put_data('doc2',@source,@user,@data1)
    @sync_store.get_data('doc2',@source,@user).should == @data1
    @sync_store.get_deleted('doc2','doc1',@source,@user).should == expected
  end
  
  # it "should return new records" do
    # @data1,@data1['1'],@data1['2'],@data1['3'] = {},@product1,@product2,@product4
    # @sync_store.put_data('md',@source,@user,@data).should == true
    # @sync_store.get_data('md',@source,@user).should == @data
    # @sync_store.put_data('bd',@source,@user,@data1)
    # @sync_store.get_data('bd',@source,@user).should == @data1
  #   
  #   result,result['3'] = {}, @product4
  #   @sync_store.get_diff('md','bd',@source,@user).should == result
  #   
  #   # result,result['3'] = {}, @product3
  #   # @sync_store.get_diff('bd','md',@source,@user).should == result
  # end
  
  # it "should return obsolete records" do
  #   
  # end
  # 
  # it "should return modified records" do
  #   
  # end
  
  
  # 
  # it "should compute backend shadow copy" do
  #   
  # end
  
  # 
  # it "should compute intersect between two sets" do
  #   
  # end
  # 
  # it "should retrieve all keys for a set" do
  #   
  # end
  
end