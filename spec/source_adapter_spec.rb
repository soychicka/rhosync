require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

class RhosyncStore::SourceAdapter 
  def inject_result(result) 
    @result = result
  end
end

describe "SourceAdapter" do
  it_should_behave_like "SourceAdapterHelper"
  
  before(:each) do    
    @path = File.join(File.dirname(__FILE__),'adapters')
    RhosyncStore.add_adapter_path(@path)
  end
  
  it "should create SourceAdapter with source" do
    @sa = SourceAdapter.create(@s)
    @sa.class.name.should == @fields[:name]
  end
  
  it "should fail to create SourceAdapter" do
    @fields[:name] = 'Broken'
    broken_source = Source.create(@fields)
    lambda { SourceAdapter.create(broken_source) }.should raise_error(Exception)
  end
  
  describe "SourceAdapter methods" do
    
    before(:each) do
      @sa = SourceAdapter.create(@s)
    end

    it "should execute SourceAdapter login method with source vars" do
      @sa.login.should == true
    end

    it "should execute SourceAdapter query method" do
      expected = {'1'=>@product1,'2'=>@product2}
      @sa.inject_result expected
      @sa.query.should == expected
    end
    
    it "should execute SourceAdapter login with current_user" do
      @sa.should_receive(:current_user).with(no_args()).and_return( @u )
      @sa.login
    end
    
    it "should execute SourceAdapter sync method" do
      expected = {'1'=>@product1,'2'=>@product2}
      @sa.inject_result expected
      @sa.query.should == expected
      @sa.sync.should == true
      @s.app.store.get_data(@s.document).should == expected
    end
    
    it "should fail gracefully if @result is missing" do
      @sa.inject_result nil
      lambda { @sa.query }.should_not raise_error
    end
    
    it "should execute SourceAdapter create method" do
      @sa.create(@product4).should == 'obj4'
    end
    
    it "should log warning if @result is missing" do
      Logger.should_receive(:error).with(SourceAdapter::MSG_NIL_RESULT_ATTRIB)
      @sa.inject_result nil
      @sa.sync
    end
    
    it "should log at debug level when result is empty" do 
      Logger.should_receive(:info).with(SourceAdapter::MSG_NO_OBJECTS)
      @sa.inject_result({ }) 
      @sa.sync
    end
  end
end