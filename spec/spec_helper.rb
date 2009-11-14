$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "RhosyncStoreDataHelper", :shared => true do
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
  end
end  