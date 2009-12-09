require File.join(File.dirname(__FILE__),'spec_helper')

describe "ClientSync" do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do
    @cs = ClientSync.new(@s,@c,2)
  end
  
  #TODO: DRY up setup and verify parts of these specs
  describe "process methods" do
    it "should handle receive cud" do
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      verify_result(@s.document.get_create_dockey => {},
        @s.document.get_update_dockey => {},
        @s.document.get_delete_dockey => {})
    end
  
    it "should handle send cud" do
      data = {'1'=>@product1,'2'=>@product2}
      expected = {'insert'=>data}
      set_test_data('test_db_storage',data)
      res = @cs.send_cud
      res.should == [{'token'=>@a.store.get_value(@cs.clientdoc.get_page_token_dockey)},
        {'count'=>data.size},{'progress_count'=>data.size},
        {'total_count'=>data.size},{'version'=>ClientSync::VERSION},expected]
      verify_result(@cs.clientdoc.get_page_dockey => data,
        @cs.clientdoc.get_delete_page_dockey => {},
        @cs.clientdoc.get_key => data)
    end
    
    it "should return read errors in send cud" do
      msg = "Error during query"
      injection = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',injection,msg,'query error')
      @cs.send_cud.should == [{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, 
        {"total_count"=>0}, {"version"=>3}, 
        {"source-error"=>{"read-error"=>{"message"=>msg}}}]
    end
    
    it "should return login errors in send cud" do
      @u.login = nil
      @cs.send_cud.should == [{"token"=>""}, {"count"=>0}, {"progress_count"=>0}, 
        {"total_count"=>0}, {"version"=>3},
        {'source-error'=>{"login-error"=>{"message"=>"Error logging in"}}}]
    end
    
    it "should return logoff errors in send cud" do
      msg = "Error logging off"
      set_test_data('test_db_storage',{},msg,'logoff error')
      res = @cs.send_cud
      res.should == [{"token"=>@a.store.get_value(@cs.clientdoc.get_page_token_dockey)}, 
        {"count"=>1}, {"progress_count"=>1}, 
        {"total_count"=>1}, {"version"=>3}, 
        {"source-error"=>{"logoff-error"=>{"message"=>msg}}, 
        "insert"=>{ERROR=>{"name"=>"logoff error", "message"=>msg, 
          "rhomobile.rhoclient"=>"1"}}}]
    end
    
    describe "send errors in send_cud" do
      it "should handle create errors" do
        msg = "Error creating record"
        created_data = {'create'=>{ERROR=>{'message'=>msg,'name'=>'error'}}}
        @cs.receive_cud(created_data)
        res = @cs.send_cud
        created_data['create'][ERROR].delete('rhomobile.rhoclient')
        res.should == [{"token"=>""}, 
          {"count"=>0}, {"progress_count"=>0}, 
          {"total_count"=>0}, {"version"=>3},
          {'create-error'=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>created_data['create'][ERROR]}}]
      end
      
      it "should handle update errors" do
        msg = "Error updating record"
        update_data = {'update'=>{ERROR=>{'message'=>msg,'name'=>'error'}}}
        @cs.receive_cud(update_data)
        res = @cs.send_cud
        update_data['update'][ERROR].delete('rhomobile.rhoclient')
        res.should == [{"token"=>""}, 
          {"count"=>0}, {"progress_count"=>0}, 
          {"total_count"=>0}, {"version"=>3},
          {'update-error'=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>update_data['update'][ERROR]}}]
      end
      
      it "should handle delete errors" do
        msg = "Error deleting record"
        delete_data = {'delete'=>{ERROR=>{'message'=>msg,'name'=>'error'}}}
        @cs.receive_cud(delete_data)
        res = @cs.send_cud
        delete_data['delete'][ERROR].delete('rhomobile.rhoclient')
        res.should == [{"token"=>""}, 
          {"count"=>0}, {"progress_count"=>0}, 
          {"total_count"=>0}, {"version"=>3},
          {'delete-error'=>{"#{ERROR}-error"=>{"message"=>msg},ERROR=>delete_data['delete'][ERROR]}}]
      end
    end
  
    it "should handle process" do
      expected = {'1'=>@product1,'2'=>@product2}
      set_test_data('test_db_storage',expected)
      params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
      @cs.receive_cud(params)
      verify_result(@s.document.get_create_dockey => {},
        @s.document.get_update_dockey => {},
        @s.document.get_delete_dockey => {},
        @s.document.get_key => expected)
    end
    
    it "should handle process with query_params" do
      expected = {'1'=>@product1}
      set_test_data('test_db_storage',{'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.send_cud(nil,params)
      verify_result(@s.document.get_key => expected,
        @cs.clientdoc.get_page_dockey => expected)
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
      set_test_data('test_db_storage',{'1'=>@product1,'2'=>@product2,'4'=>@product4})
      params = {'name' => 'iPhone'}
      @cs.send_cud(nil,params)
      token = @store.get_value(@cs.clientdoc.get_page_token_dockey)
      @cs.send_cud.should == [{"token"=>token}, {"count"=>1}, {"progress_count"=>1}, 
        {"total_count"=>1}, {"version"=>3},{'insert' => expected}]
      @cs.send_cud(token).should == [{"token"=>""}, {"count"=>0}, {"progress_count"=>1}, 
        {"total_count"=>1}, {"version"=>3}, {}]
      @store.get_data(@cs.clientdoc.get_page_dockey).should == {}              
      @store.get_value(@cs.clientdoc.get_page_token_dockey).should == nil
    end
  end
end