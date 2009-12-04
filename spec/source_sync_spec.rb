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
    msg = "Error logging in"
    Logger.should_receive(:error).with("SourceAdapter raised login exception: #{msg}")
    @u.login = nil
    @ss = SourceSync.new(@s)
    @ss.adapter.inject_result({'3'=>@product3})
    @ss.process
    @a.store.get_data(@s.document.get_source_errors_dockey).should == {'login-error'=>{'message'=>msg}}
  end
  
  it "should raise SourceAdapterLogoffException if logoff fails" do
    msg = "Error logging off"
    Logger.should_receive(:error).with("SourceAdapter raised logoff exception: #{msg}")
    @ss = SourceSync.new(@s)
    @ss.adapter.inject_result({'1'=>{'name'=>'logoff'}})
    @ss.process
    @a.store.get_data(@s.document.get_source_errors_dockey).should == {'logoff-error'=>{'message'=>msg}}
  end
  
  describe "methods" do
    before(:each) do
      @ss = SourceSync.new(@s)
      @clientdoc = Document.new('cd',@a.id,@s.user.id,@c.id,@s.name)
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
        @crd = @s.document.get_create_dockey
        @a.store.put_data(@crd,created_data)
        @ss.create.should == true
        @a.store.get_data(@s.document.get_create_errors_dockey).should == {}
        @a.store.get_data(@s.document.get_create_links_dockey).should == {}
        @a.store.get_data(@crd).should == {}
      end
    
      it "should do create where adapter.create returns object link" do
        created_data = {'4'=>@product4}
        created_data['4']['rhomobile.rhoclient'] = @c.id.to_s
        @crd = @s.document.get_create_dockey
        @a.store.put_data(@crd,created_data)
        @ss.create.should == true
        @a.store.get_data(@s.document.get_create_errors_dockey).should == {}
        @a.store.get_data(@clientdoc.get_create_links_dockey).should == { '4' => { 'l' => 'obj4' } }
        @a.store.get_data(@crd).should == {}
      end
    
      it "should raise exception on adapter.create" do
        created_data = {'4'=>@product4,'3'=>@product3,'2'=>@product2}
        created_data.each { |key,value| value['rhomobile.rhoclient'] = @c.id.to_s }
        @crd = @s.document.get_create_dockey
        @a.store.put_data(@crd,created_data)
        @ss.create.should == true
        @product3.delete('rhomobile.rhoclient')
        expected = {"3-error"=>{"message"=>"Error creating record"}, "3"=>@product3}
        @a.store.get_data(@clientdoc.get_create_errors_dockey).should == expected
        @a.store.get_data(@crd).should == {'4'=>@product4}
      end
    end
    
    describe "update" do
      it "should do update with no errors" do
        update_data = {'4'=> { 'price' => '199.99' }}
        @ud = @s.document.get_update_dockey
        @a.store.put_data(@ud,update_data)
        @ss.update.should == true
        @a.store.get_data(@s.document.get_update_errors_dockey).should == {}
        @a.store.get_data(@ud).should == {}
      end
      
      it "should do update with errors" do
        update_data = {'4'=> { 'price' => '199.99' },'3'=>{ 'name' => 'Fuze' }}
        update_data.each { |key,value| value['rhomobile.rhoclient'] = @c.id.to_s }
        @ud = @s.document.get_update_dockey
        @a.store.put_data(@ud,update_data)
        @ss.update.should == true
        expected = {"3-error"=>{"message"=>"Error updating record"}, "3"=>{"name"=>"Fuze"}}
        expected['3'].delete('rhomobile.rhoclient')
        @a.store.get_data(@clientdoc.get_update_errors_dockey).should == expected
        @a.store.get_data(@ud).should == {'4'=> { 'price' => '199.99', 'rhomobile.rhoclient' => @c.id.to_s }}
      end
    end
    
    describe "delete" do
      it "should do delete with no errors" do
        delete_data = {'4'=>@product4}
        @dd = @s.document.get_delete_dockey
        @a.store.put_data(@dd,delete_data)
        @ss.delete.should == true
        @a.store.get_data(@s.document.get_delete_errors_dockey).should == {}
        @a.store.get_data(@dd).should == {}
      end
      
      it "should do delete with errors" do
        delete_data = {'4'=>@product4,'3'=>@product3,'2'=>@product2}
        delete_data.each { |key,value| value['rhomobile.rhoclient'] = @c.id.to_s }
        @dd = @s.document.get_delete_dockey
        @a.store.put_data(@dd,delete_data)
        @ss.delete.should == true
        expected = {"3-error"=>{"message"=>"Error deleting record"}, "3"=>@product3}
        expected['3'].delete('rhomobile.rhoclient')
        @a.store.get_data(@clientdoc.get_delete_errors_dockey).should == expected
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
      
      it "should do read with no exception and remove existing errors" do
        @s.app.store.put_data(@s.document.get_source_errors_dockey,
                              {'read-error'=>{'message'=>'failed'}},true)
        expected = {'1'=>@product1,'2'=>@product2}
        @ss.adapter.inject_result expected
        @ss.read.should == true
        @a.store.get_data(@s.document.get_key).should == expected
        @a.store.get_data(@s.document.get_source_errors_dockey).should == {}
      end
      
      it "should do read with exception raised" do
        msg = "Error during query"
        Logger.should_receive(:error).with("SourceAdapter raised read exception: #{msg}")
        @ss.adapter.inject_result({'3'=>@product3})
        @ss.read.should == true
        @a.store.get_data(@s.document).should == {}
        @a.store.get_data(@s.document.get_source_errors_dockey).should == {'read-error'=>{'message'=>msg}}
      end
    end
  end
end