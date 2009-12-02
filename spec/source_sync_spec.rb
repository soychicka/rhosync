require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "SourceSync" do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do    
    @path = File.join(File.dirname(__FILE__),'adapters')
    RhosyncStore.add_adapter_path(@path)
  end
  
  it "should create SourceSync" do
    @ss = SourceSync.new(@s)
    @ss.adapter.is_a?(SampleAdapter).should == true
  end
  
  it "should fail to create SourceSync with InvalidArgumentError" do
    lambda { SourceSync.new(nil) }.should raise_error(InvalidArgumentError, 'Invalid source')
  end
  
  it "should raise SourceAdapterLoginException if login fails" do
    Logger.should_receive(:error).with("SourceAdapter raised login exception: Error logging in")
    @u.login = nil
    @ss = SourceSync.new(@s)
    @ss.adapter.inject_result({'3'=>@product3})
    @ss.process
  end
  
  it "should raise SourceAdapterLogoffException if logoff fails" do
    Logger.should_receive(:error).with("SourceAdapter raised logoff exception: Error logging off")
    @ss = SourceSync.new(@s)
    @ss.adapter.inject_result({'1'=>{'name'=>'logoff'}})
    @ss.process
  end
  
  describe "methods" do
    before(:each) do
      @ss = SourceSync.new(@s)
    end
    
    it "should process source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      @ss.adapter.inject_result expected
      @ss.process
      @a.store.get_data(@s.document.get_key).should == expected
    end
    
    it "should call methods in source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      @ss.adapter.should_receive(:login).once.with(no_args()).and_return(true)
      @ss.adapter.should_receive(:query).once.with(no_args()).and_return(expected)
      @ss.adapter.should_receive(:sync).once.with(no_args()).and_return(true)
      @ss.adapter.should_receive(:logoff).once.with(no_args()).and_return(nil)
      @ss.process
    end
    
    describe "create" do
      it "should do create where adapter.create returns nil" do
        created_data = {'2'=>@product2}
        @crd = @s.document.get_created_dockey
        @a.store.put_data(@crd,created_data)
        @ss.create.should == true
        @a.store.get_data(@s.document.get_created_errors_dockey).should == {}
        @a.store.get_data(@s.document.get_created_links_dockey).should == {}
        @a.store.get_data(@crd).should == {}
      end
    
      it "should do create where adapter.create returns object link" do
        created_data = {'4'=>@product4}
        @crd = @s.document.get_created_dockey
        @a.store.put_data(@crd,created_data)
        @ss.create.should == true
        @a.store.get_data(@s.document.get_created_errors_dockey).should == {}
        @a.store.get_data(@s.document.get_created_links_dockey).should == { '4' => { 'l' => 'obj4' } }
        @a.store.get_data(@crd).should == {}
      end
    
      it "should raise exception on adapter.create" do
        created_data = {'4'=>@product4,'3'=>@product3,'2'=>@product2}
        @crd = @s.document.get_created_dockey
        @a.store.put_data(@crd,created_data)
        @ss.create.should == true
        @a.store.get_data(@s.document.get_created_errors_dockey).should == {'3'=>@product3}
        @a.store.get_data(@crd).should == {'4'=>@product4}
      end
    end
    
    describe "update" do
      it "should do update with no errors" do
        update_data = {'4'=> { 'price' => '199.99' }}
        @ud = @s.document.get_updated_dockey
        @a.store.put_data(@ud,update_data)
        @ss.update.should == true
        @a.store.get_data(@s.document.get_updated_errors_dockey).should == {}
        @a.store.get_data(@ud).should == {}
      end
      
      it "should do update with errors" do
        update_data = {'4'=> { 'price' => '199.99' },'3'=>{ 'name' => 'Fuze' }}
        @ud = @s.document.get_updated_dockey
        @a.store.put_data(@ud,update_data)
        @ss.update.should == true
        @a.store.get_data(@s.document.get_updated_errors_dockey).should == { '3' => { 'name' => 'Fuze' }}
        @a.store.get_data(@ud).should == {'4'=> { 'price' => '199.99' }}
      end
    end
    
    describe "delete" do
      it "should do delete with no errors" do
        delete_data = {'4'=>@product4}
        @dd = @s.document.get_deleted_dockey
        @a.store.put_data(@dd,delete_data)
        @ss.delete.should == true
        @a.store.get_data(@s.document.get_deleted_errors_dockey).should == {}
        @a.store.get_data(@dd).should == {}
      end
      
      it "should do delete with errors" do
        delete_data = {'4'=>@product4,'3'=>@product3,'2'=>@product2}
        @dd = @s.document.get_deleted_dockey
        @a.store.put_data(@dd,delete_data)
        @ss.delete.should == true
        @a.store.get_data(@s.document.get_deleted_errors_dockey).should == {'3'=>@product3}
        @a.store.get_data(@dd).should == {'4'=>@product4}
      end
    end
    
    describe "read" do
      it "should do read with no exception" do
        expected = {'1'=>@product1,'2'=>@product2}
        @ss.adapter.inject_result expected
        @ss.read.should == true
        @a.store.get_data(@s.document.get_key).should == expected
      end
      
      it "should do read with exception raised" do
        Logger.should_receive(:error).with("SourceAdapter raised query exception: Error during query")
        @ss.adapter.inject_result({'3'=>@product3})
        @ss.read.should == true
        @a.store.get_data(@s.document).should == {}
      end
    end
  end
end