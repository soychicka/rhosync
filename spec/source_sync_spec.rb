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
    @ss = SourceSync.new(@a,@u,@s)
    @ss.app.should == @a
    @ss.user.should == @u
    @ss.source.should == @s
  end
  
  it "should fail to create SourceSync with InvalidArgumentError" do
    lambda { SourceSync.new(nil,@u,@s) }.should raise_error(InvalidArgumentError, 'Invalid app')
    lambda { SourceSync.new(@a,nil,@s) }.should raise_error(InvalidArgumentError, 'Invalid user')
    lambda { SourceSync.new(@a,@u,nil) }.should raise_error(InvalidArgumentError, 'Invalid source')
  end
  
  it "should raise SourceAdapterLoginException if login fails" do
    @u.login = nil
    @ss = SourceSync.new(@a,@u,@s)
    lambda { @ss.process }.should raise_error(SourceAdapterLoginException, 'Error logging in')
  end
  
  describe "process" do
    before(:each) do
      @ss = SourceSync.new(@a,@u,@s)
    end
    
    it "should do create where adapter.create returns nil" do
      created_data = {'4'=>@product4}
      @ss.adapter.should_receive(:create).once.with(created_data['4']).and_return(nil)
      @crd = @s.document.get_created_doc
      @a.store.put_data(@crd,created_data)
      @ss.create.should == true
      @a.store.get_data(@s.document.get_created_errors_doc).should == {}
      @a.store.get_data(@crd).should == {}
    end
    
    it "should raise exception on adapter.create" do
      created_data = {'4'=>@product4,'3'=>@product3,'2'=>@product2}
      @crd = @s.document.get_created_doc
      @a.store.put_data(@crd,created_data)
      @ss.create.should == true
      @a.store.get_data(@s.document.get_created_errors_doc).should == {'3'=>@product3}
      @a.store.get_data(@crd).should == {'4'=>@product4}
    end
    
    it "should process source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      @ss.process.should == true
      @a.store.get_data(@ss.source.document).should == expected
    end
    
    it "should call methods in source adapter" do
      expected = {'1'=>@product1,'2'=>@product2}
      @ss.adapter.should_receive(:login).once.with(no_args()).and_return(true)
      @ss.adapter.should_receive(:query).once.with(no_args()).and_return(expected)
      @ss.adapter.should_receive(:sync).once.with(no_args()).and_return(true)
      @ss.adapter.should_receive(:logoff).once.with(no_args()).and_return(nil)
      @ss.process.should == true
    end
  end
end