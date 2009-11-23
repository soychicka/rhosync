$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "RhosyncStoreDataHelper", :shared => true do
  before(:each) do
    @store = RhosyncStore::Store.new
    @store.db.flushdb
    
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
    
    @data = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
    
    @mdoc = Document.new('md',@source,@user)
    @cdoc = Document.new('cd',@source,@user)
  end
end  

describe "SourceAdapterHelper", :shared => true do
  it_should_behave_like "RhosyncStoreDataHelper"
  
  before(:each) do
    @a_fields = { :name => 'testapp' }
    @a = App.create(@a_fields)
    @u_fields = {
      :login => 'testuser',
      :password => 'testpass'
    }
    @u = User.create(@u_fields) 
    @fields = {
      :name => 'SampleAdapter',
      :url => 'http://example.com',
      :login => 'testuser',
      :password => 'testpass',
      :user_id => @u.id,
      :app_id => @a.id
    }
    @s = Source.create(@fields)
  end
end