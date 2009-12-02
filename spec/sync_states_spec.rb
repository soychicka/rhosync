require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Sync Server States" do
  it_should_behave_like "StorageStateHelper"
  
  before(:each) do    
    @path = File.join(File.dirname(__FILE__),'adapters')
    RhosyncStore.add_adapter_path(@path)
    @cs = ClientSync.new(@s,@c,2)
  end
  
  describe "do initial sync" do
    it "should sync with backend, setup masterdoc, clientdoc, and page documents" do
      expected = {'1'=>@product1,'2'=>@product2}
      @cs.source_sync.adapter.inject_result @data
      @cs.process
      res = @cs.send_cud
      exp_token = @s.app.store.get_value(@cs.clientdoc.get_page_token_dockey)
      res.should == {'token'=>exp_token,'insert'=>expected}
      @s.app.store.get_data(@s.document.get_key).should == @data
      @s.app.store.get_data(@cs.clientdoc.get_page_dockey).should == expected
      @s.app.store.get_data(@cs.clientdoc.get_key).should == expected
    end
    
    
  end
end