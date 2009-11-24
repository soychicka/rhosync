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
  
  it "should fail to create SourceSync with IllegalArgumentError" do
    lambda { SourceSync.new(nil,@u,@s).should raise_error(IllegalArgumentError, 'Invalid app') }
    lambda { SourceSync.new(@a,nil,@s).should raise_error(IllegalArgumentError, 'Invalid user') }
    lambda { SourceSync.new(@a,@u,nil).should raise_error(IllegalArgumentError, 'Invalid source') }
  end
  
  describe "SourceSync process" do
    before(:each) do
      @ss = SourceSync.new(@a,@u,@s)
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