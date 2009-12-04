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
    it "should handle receive cud" do
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      @a.store.get_data(@s.document.get_create_dockey).should == {}
      @a.store.get_data(@s.document.get_update_dockey).should == {}
      @a.store.get_data(@s.document.get_delete_dockey).should == {}
    end
  
    it "should handle send cud" do
      master_doc = Document.new('md',@a.id,@u.id,'0',@s.name)
      data = {'1'=>@product1,'2'=>@product2}
      expected = {'insert'=>data}
      @a.store.put_data(master_doc.get_key,data)
      res = @cs.send_cud
      expected['token'] = @a.store.get_value(@cs.clientdoc.get_page_token_dockey)
      res.should == expected
      @a.store.get_data(@cs.clientdoc.get_page_dockey).should == data
      @a.store.get_data(@cs.clientdoc.get_delete_page_dockey).should == {}
      @a.store.get_data(@cs.clientdoc.get_key).should == data
    end
    
    it "should return read errors in send cud" do
      injection = {'1'=>@product1,'2'=>@product2,'3'=>@product3}
      @cs.source_sync.adapter.inject_result injection
      @cs.send_cud.should == {'source-error'=>{"read-error"=>{"message"=>"Error during query"}}}
    end
    
    it "should return login errors in send cud" do
      @u.login = nil
      @cs.send_cud.should == {'source-error'=>{"login-error"=>{"message"=>"Error logging in"}}}
    end
    
    it "should return logoff errors in send cud" do
      data = {'1'=>{'name'=>'logoff'}}
      @cs.source_sync.adapter.inject_result(data)
      res = @cs.send_cud
      token = @a.store.get_value(@cs.clientdoc.get_page_token_dockey)
      res.should == {'source-error'=>{"logoff-error"=>{"message"=>"Error logging off"}},'insert'=>data,'token'=>token}      
    end
    
    describe "send errors in send_cud" do
      it "should handle create errors" do
        created_data = {'create'=>{'4'=>@product4,'3'=>@product3}}
        injection = {'1'=>@product1,'2'=>@product2}
        @cs.source_sync.adapter.inject_result injection
        @cs.receive_cud(created_data)
        res = @cs.send_cud
        @product3.delete('rhomobile.rhoclient')
        token = @a.store.get_value(@cs.clientdoc.get_page_token_dockey)
        expected = {'insert'=>injection,
                    'create-error'=>{"3-error"=>{"message"=>"Error creating record"},'3'=>@product3},
                    'token'=>token,
                    'links'=>{"4"=>{"l"=>"obj4"}}}
        res.should == expected
      end
      
      it "should handle update errors" do
        update_data = {'update'=>{'3'=>{'name'=>'Fuze'}}}
        injection = {'1'=>@product1,'2'=>@product2}
        @cs.source_sync.adapter.inject_result injection
        @cs.receive_cud(update_data)
        res = @cs.send_cud
        token = @a.store.get_value(@cs.clientdoc.get_page_token_dockey)
        expected = {'insert'=>injection,
                    'update-error'=>{"3-error"=>{"message"=>"Error updating record"},'3'=>{'name'=>'Fuze'}},
                    'token'=>token}
        res.should == expected
      end
      
      it "should handle delete errors" do
        delete_data = {'delete'=>{'3'=>@product3}}
        injection = {'1'=>@product1,'2'=>@product2}
        @cs.source_sync.adapter.inject_result injection
        @cs.receive_cud(delete_data)
        res = @cs.send_cud
        token = @a.store.get_value(@cs.clientdoc.get_page_token_dockey)
        @product3.delete('rhomobile.rhoclient')
        expected = {'insert'=>injection,
                    'delete-error'=>{"3-error"=>{"message"=>"Error deleting record"},'3'=>@product3},
                    'token'=>token}
        res.should == expected
      end
    end
  
    it "should handle process" do
      expected = {'1'=>@product1,'2'=>@product2}
      @cs.source_sync.adapter.inject_result expected
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      @a.store.get_data(@s.document.get_create_dockey).should == {}
      @a.store.get_data(@s.document.get_update_dockey).should == {}
      @a.store.get_data(@s.document.get_delete_dockey).should == {}
      @a.store.get_data(@s.document.get_key).should == expected
    end
    
    it "should handle process with query_params" do
      expected = {'1'=>@product1}
      @cs.source_sync.adapter.inject_result({'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.send_cud(nil,params)
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
      @store.get_data(@cs.clientdoc.get_delete_page_dockey).should == @expected
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
    
    it "should resend page if page exists and no token provided" do
      expected = {'1'=>@product1}
      @cs.source_sync.adapter.inject_result({'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.send_cud(nil,params)
      token = @store.get_value(@cs.clientdoc.get_page_token_dockey)
      @cs.send_cud.should == {'insert' => expected, 'token'=>token}
      @cs.send_cud(token).should == {}
      @store.get_data(@cs.clientdoc.get_page_dockey).should == {}              
      @store.get_value(@cs.clientdoc.get_page_token_dockey).should == nil
    end
  end
end