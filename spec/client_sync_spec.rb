require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "ClientSync" do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do    
    @path = File.join(File.dirname(__FILE__),'adapters')
    RhosyncStore.add_adapter_path(@path)
    @cs = ClientSync.new(@s,@c,2)
  end
  
  describe "process methods" do
    it "should handle receive data" do
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      @a.store.get_data(@s.document.get_created_dockey).should == params['create']
      @a.store.get_data(@s.document.get_updated_dockey).should == params['update']
      @a.store.get_data(@s.document.get_deleted_dockey).should == params['delete']
    end
  
    it "should handle send data" do
      master_doc = Document.new('md',@a.id,@u.id,'0',@s.name)
      data = {'1'=>@product1,'2'=>@product2}
      expected = {'insert'=>data}
      @a.store.put_data(master_doc.get_key,data)
      res = @cs.send_cud
      expected['token'] = @a.store.get_value(@cs.clientdoc.get_page_token_dockey)
      res.should == expected
      @a.store.get_data(@cs.clientdoc.get_page_dockey).should == data
      @a.store.get_data(@cs.clientdoc.get_deleted_page_dockey).should == {}
      @a.store.get_data(@cs.clientdoc.get_key).should == data
    end
  
    it "should handle process" do
      expected = {'1'=>@product1,'2'=>@product2}
      @cs.source_sync.adapter.inject_result expected
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.process(params)
      @a.store.get_data(@s.document.get_created_dockey).should == {}
      @a.store.get_data(@s.document.get_updated_dockey).should == {}
      @a.store.get_data(@s.document.get_deleted_dockey).should == {}
      @a.store.get_data(@s.document.get_key).should == expected
    end
    
    it "should handle process with query_params" do
      expected = {'1'=>@product1}
      @cs.source_sync.adapter.inject_result({'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.process({},params)
      @cs.send_cud
      @a.store.get_data(@s.document.get_key).should == expected
      @a.store.get_data(@cs.clientdoc.get_page_dockey).should == expected
    end
  
    it "should handle reset" do
      @a.store.put_data(@cs.clientdoc.get_key,@data)
      ClientSync.reset(@a,@u,@c)
      @a.store.get_data(@cs.clientdoc.get_key).should == {}
    end
  end
  
  describe "page methods" do
    it "should return diffs between master documents and client documents limited by page size" do
      @store.put_data(@s.document.get_key,@data).should == true
      @store.get_data(@s.document.get_key).should == @data

      @expected = {'1'=>@product1,'2'=>@product2}
      @cs.compute_page.should == @expected
      @store.get_data(@cs.clientdoc.get_page_dockey).should == @expected      
    end

    it "appends diff to the client document" do
      @cd = {'3'=>@product3}  
      @store.put_data(@cdoc.get_key,@cd)
      @store.get_data(@cdoc.get_key).should == @cd

      @page = {'1'=>@product1,'2'=>@product2}
      @expected = {'1'=>@product1,'2'=>@product2,'3'=>@product3}

      @store.put_data(@cdoc.get_key,@page,true).should == true
      @store.get_data(@cdoc.get_key).should == @expected
    end

    it "should return deleted objects in the client document" do
      @store.put_data(@s.document.get_key,@data).should == true
      @store.get_data(@s.document.get_key).should == @data

      @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
      @store.put_data(@cs.clientdoc.get_key,@cd)
      @store.get_data(@cs.clientdoc.get_key).should == @cd

      @expected = {'4'=>@product4}
      @cs.compute_deleted_page.should == @expected
      @store.get_data(@cs.clientdoc.get_deleted_page_dockey).should == @expected
    end  

    it "should delete objects from client document" do
      @store.put_data(@s.document.get_key,@data).should == true
      @store.get_data(@s.document.get_key).should == @data

      @cd = {'1'=>@product1,'2'=>@product2,'3'=>@product3,'4'=>@product4}  
      @store.put_data(@cs.clientdoc.get_key,@cd)
      @store.get_data(@cs.clientdoc.get_key).should == @cd

      @store.delete_data(@cs.clientdoc.get_key,@cs.compute_deleted_page).should == true
      @store.get_data(@cs.clientdoc.get_key).should == @data 
    end
  end
end