require File.dirname(__FILE__) + "/../../../spec_helper"
require File.dirname(__FILE__) + "/sync_spec_helper"
require 'sync'

describe "Sync.Synchronizer" do
  before do 
    @sync_data = {}
    @source_id = 123
    @object_limit = 456
    @user_id = 789
    ObjectValue.all.should be_empty
  end
  
  describe "sync" do 
    it "should ignore the complete object if it contains invalid attributes" do
      sync triple("51", "attrib", "valid", "attrib_type", "invalid", "id", "invalid")
      ObjectValue.all.should be_empty
    end
    
    it "should not ignore valid object when invalid objects are present" do 
      sync triples( 
        triple("51", "attrib_type", "invalid", "id", "invalid"),
        triple("52", "attrib", "valid!")
      )
      ObjectValue.all.size.should == 1
    end
    
    it "should use default source_id from @source" do
      pending "Should verify that ObjectParser is initialized with source_id"
      expected_source_id = 321
      sync triple("123", "attrib-name", "value"), :source_id => expected_source_id
      ObjectValue.first.source_id.should == expected_source_id
    end
    
    it "should create an object_value" do
      data = triple("1234", "attrib", "value")
      Sync::Synchronizer.new(data, @source_id).sync
      ObjectValue.all.size.should == 1
    end
    
    it "should not insert more items than the configured limit" do
      sync triples( 
        triple("51", "attrib", "value"),
        triple("52", "attrib", "value"),
        triple("53", "attrib", "value"),
        triple("54", "attrib", "value")
      ), :limit => (expected_object_count = 3)
                                      
      ObjectValue.all.size.should == expected_object_count
    end
    
    it "should create one ObjectValue per attribute" do 
      data = triples(triple("123", "name1", "value1"),
                      triple("789", "name3", "value3", "name4", "value4") )
      Sync::Synchronizer.new(data, @source_id).sync
      ObjectValue.all.size.should == 3
    end
  end
  
  
  describe "initialize" do 
    it "should raise error when sync_data param is nil" do 
      lambda { Sync::Synchronizer.new(nil, @source_id) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should raise error when sync_data param is not a hash" do 
      mock = mock("non-hash")
      mock.should_receive(:is_a?).with(Hash).and_return(false)
      lambda { Sync::Synchronizer.new(mock, @source_id) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should allow sync_data param hash to be empty" do 
      lambda { Sync::Synchronizer.new({}, @source_id) }.should_not raise_error
    end
    
    it "should raise error when source_id param is nil" do 
      lambda { Sync::Synchronizer.new(@sync_data, nil) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should raise error if source_id is less than 1" do 
      lambda { Sync::Synchronizer.new(@sync_data, 0) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should raise error if source_id param is not Fixnum" do
      mock = mock("non-fixnum", :null_object => true)
      mock.should_receive(:is_a?).with(Fixnum).and_return(false)
      lambda { Sync::Synchronizer.new(@sync_data, mock) }.should raise_error(Sync::IllegalArgumentError)
    end 
    
    it "should not require limit and user_id params" do 
      lambda { Sync::Synchronizer.new(@sync_data, @source_id) }.should_not raise_error
    end
    
    
    it "should raise error if object_limit param is not Fixnum" do
      mock = mock("non-fixnum", :null_object => true)
      mock.should_receive(:is_a?).with(Fixnum).and_return(false)
      lambda { Sync::Synchronizer.new(@sync_data, @source_id, mock) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should raise error if object_limit is less than 1" do 
      lambda { Sync::Synchronizer.new(@sync_data, @source_id, 0) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should allow object_limit to be nil" do 
      lambda { Sync::Synchronizer.new(@sync_data, @source_id, nil) }.should_not raise_error
    end
    
    it "should raise error if user_id param is not Fixnum" do 
      mock = mock("non-fixnum", :null_object => true)
      mock.should_receive(:is_a?).with(Fixnum).and_return(false)
      lambda { Sync::Synchronizer.new(@sync_data, @source_id, @object_limit, mock) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should raise error if user_id less than 1" do 
      lambda { Sync::Synchronizer.new(@sync_data, @source_id, @object_limit, 0) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should allow user_id to be nil" do 
      lambda { Sync::Synchronizer.new(@sync_data, @source_id, nil, nil) }.should_not raise_error
    end
    
    it "should save params as attributes" do 
      obj = Sync::Synchronizer.new(@sync_data, @source_id, @object_limit, @user_id)
      obj.sync_data.should == @sync_data
      obj.object_limit.should == @object_limit
      obj.user_id.should == @user_id
      obj.source_id.should == @source_id
    end
  end
  
  # Local helper
  def sync(data, options = {})
    source_id = options[:source_id] ||= @source_id
    limit = options[:limit] ||= nil
    user_id = options[:user_id] ||= nil
    Sync::Synchronizer.new(data, source_id, limit, user_id).sync
  end

end
