require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "ClientSync" do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do    
    @path = File.join(File.dirname(__FILE__),'adapters')
    RhosyncStore.add_adapter_path(@path)
    @cs = ClientSync.new(@a,@u,@c,@s)
  end
  
  it "should handle receive data" do
    params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
    @cs.receive_cud(params)
    @a.store.get_data(@s.document.get_created_doc).should == params['create']
    @a.store.get_data(@s.document.get_updated_doc).should == params['update']
    @a.store.get_data(@s.document.get_deleted_doc).should == params['delete']
  end
  
  it "should handle send data" do
    master_doc = Document.new('md',@a.id,@u.id,@c.id,@s.name)
    data = {'1'=>@product1,'2'=>@product2}
    expected = {'insert'=>data,'delete'=>{}}
    @a.store.put_data(master_doc,data)
    @cs.send_cud.should == expected
    @cs.client_store.get_page.should == data
    @cs.client_store.get_deleted_page.should == {}
    @a.store.get_data(@cs.client_store.clientdoc).should == data
  end
  
  it "should handle process" do
    expected = {'1'=>@product1,'2'=>@product2}
    @cs.source_sync.adapter.inject_result expected
    params = {'create'=>{'1'=>@product1},'update'=>{'2'=>@product2},'delete'=>{'3'=>@product3}}
    @cs.process(params)
    @a.store.get_data(@s.document.get_created_doc).should == {}
    @a.store.get_data(@s.document.get_updated_doc).should == {}
    @a.store.get_data(@s.document.get_deleted_doc).should == {}
    @a.store.get_data(@s.document).should == expected
  end
end