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
    start = (Time.now.to_f * 1000).to_i
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.get_timestamp('doc1',@source,@user).should >= start
    @sync_store.get_data('doc1',@source,@user).should == @data
  end
  
  it "should replace simple data to existing set" do
    new_data,new_data['3'] = {},{'name' => 'Droid','brand' => 'Google'}
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.put_data('doc1',@source,@user,new_data)
    @sync_store.get_data('doc1',@source,@user).should == new_data
  end
  
  it "should return ids that were deleted in doc2" do
    @data1,@data1['1'],@data1['2'] = {},@product1,@product2
    expected = ['3']
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.get_data('doc1',@source,@user).should == @data
    @sync_store.put_data('doc2',@source,@user,@data1)
    @sync_store.get_data('doc2',@source,@user).should == @data1
    @sync_store.get_diff_ids('doc2','doc1',@source,@user).should == expected
  end
  
  it "should return ids that were created in doc2" do
    @data1,@data1['1'],@data1['2'],@data1['3'],@data['4'] = {},@product1,@product2,@product3,@product4
    expected = ['4']
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.get_data('doc1',@source,@user).should == @data
    @sync_store.put_data('doc2',@source,@user,@data1)
    @sync_store.get_data('doc2',@source,@user).should == @data1
    @sync_store.get_diff_ids('doc2','doc1',@source,@user).should == expected
  end
  
  it "should return attributes modified in doc2" do
    @sync_store.put_data('doc1',@source,@user,@data).should == true
    @sync_store.get_data('doc1',@source,@user).should == @data
    
    @product3['price'] = '59.99'
    expected = { '3' => { 'price' => '59.99' } }
    @data1,@data1['1'],@data1['2'],@data1['3'] = {},@product1,@product2,@product3
    
    @sync_store.put_data('doc2',@source,@user,@data1)
    @sync_store.get_data('doc2',@source,@user).should == @data1
    @sync_store.get_diff_data('doc1','doc2',@source,@user).should == expected
  end
end