require File.dirname(__FILE__) + "/../../spec_helper"

class SourceAdapter 
  def inject_result(result) 
    @result = result
  end
end

describe SourceAdapter do 
  describe "sync" do 
    before do
      ObjectValue.all(&:destroy)
      @adapter = SourceAdapter.new
      @default_stubs = {:current_user => nil, :limit => nil }
      @adapter.stub(@default_stubs)
      
      @adapter.should_not_receive(:puts)
      @adapter.should_not_receive(:p)
    end
    
    describe "(when source is given in initializer)" do 
      before do 
        @source = mock("Source", @default_stubs)
        @adapter = SourceAdapter.new(@source)
        @injected_result = triplets( triplet("51", "attrib", "value"),
                                     triplet("52", "attrib", "value") )
        @adapter.inject_result @injected_result
      end
      
      it "should ask for limit from source" do 
        @source.should_receive(:limit).at_least(1).and_return(expected_limit = 1)
        do_sync
        expected_limit.should < @injected_result.size
        ObjectValue.all.size.should == expected_limit
      end
      
      it "should ask for current_user from source" do 
        @source.should_receive(:current_user).and_return(nil)
        do_sync
        ObjectValue.all.size.should == @injected_result.size
      end
      
      it "should use source.id for for source_id value"
    end
    
    describe "(when not initialized with source)" do
      before do 
        @injected_result = triplets( triplet("51", "attrib", "value"),
                                     triplet("52", "attrib", "value") )
        @adapter.inject_result @injected_result
      end
      
      it "should ask for limit from self" do 
        @adapter.should_receive(:limit).at_least(1).and_return(expected_limit = 1)
        do_sync
        expected_limit.should < @injected_result.size
        ObjectValue.all.size.should == expected_limit
      end
      
      it "should ask for current_user from self" do 
        @adapter.should_receive(:current_user).and_return(nil)
        do_sync
        ObjectValue.all.size.should == @injected_result.size
      end
      
      it "should use self.id for for source_id value"
    end
    
    it "should work with String id:s" do 
      @adapter.inject_result triplet(expected_object = "a-string", "name", "value")
      do_sync
      ObjectValue.first.object.should == expected_object
    end
    
    it "should ignore object_values named 'id'" do
      @adapter.inject_result triplet("123", "id", "ignore me")
      do_sync 
      ObjectValue.all.should be_empty
    end
    
    it "should ignore object_value where name is blank" do 
      @adapter.inject_result triplet("123", "", "ignore me")
      do_sync 
      ObjectValue.all.should be_empty
      
      @adapter.inject_result triplet("123", nil, "ignore me")
      do_sync 
      ObjectValue.all.should be_empty
    end
    
    it "should ignore object_value where value is blank" do 
      @adapter.inject_result triplet("123", "attrib-name", "")
      do_sync 
      ObjectValue.all.should be_empty
      
      @adapter.inject_result triplet("123", "attrib-name", nil)
      do_sync 
      ObjectValue.all.should be_empty
    end
    
    it "should use default source_id from @source" do 
      @adapter.inject_result triplet("123", "attrib-name", "value")
      @adapter.stub(:id).and_return(expected_source_id = 321)
      do_sync
      ObjectValue.first.source_id.should == expected_source_id
    end
    
    it "should override default source_id when given as object_value" do 
      pending "This spec will not work. I doubt this part of the SourceAdapter implementation has ever been run"
      
      @adapter.inject_result triplet("123", 
                                     "attrib-name", "value", 
                                     :source_id, expected_source_id = 1234)
      do_sync
      ObjectValue.first.source_id.should == expected_source_id
    end
    
    it "should not insert more items than the configured limit" do 
      @adapter.inject_result triplets( 
        triplet("51", "attrib", "value"),
        triplet("52", "attrib", "value"),
        triplet("53", "attrib", "value"),
        triplet("54", "attrib", "value")
      )
                                      
      @adapter.stub(:limit).and_return(expected_sync_count = 3)
      do_sync
      ObjectValue.all.size.should == expected_sync_count
    end
    
    it "should save an ObjectValue" do
      @adapter.inject_result triplet("object-id", "attrib-name", expected_value = "attrib-value")
      do_sync
      ObjectValue.all.size.should == 1
    end
    
    
    it "should save ObjectValue.value" do
      @adapter.inject_result triplet("object-id", "attrib-name", expected_value = "attrib-value")
      do_sync
      ObjectValue.first.value.should == expected_value
    end
    
    it "should save ObjectValue.attrib" do
      @adapter.inject_result triplet("object-id", expected_attrib = "attrib-name", "attrib-value")
      do_sync
      ObjectValue.first.attrib.should == expected_attrib
    end
    
    it "should store given id as ObjectValue.object" do 
      @adapter.inject_result triplet(expected_object = "55", "attrib", "value")
      do_sync
      ObjectValue.first.object.should == expected_object
    end
    
    it "should save the user id" do 
      user = mock("User", :id => (expected_user_id = 1234))
      
      @adapter.stub(:current_user).and_return(user)
      @adapter.inject_result triplet("object-id", "attrib-name", "attrib-value")
      do_sync
      ObjectValue.first.user_id.should == expected_user_id
    end
    
    it "should allow user id to be nil" do 
      @adapter.should_receive(:current_user).and_return(nil)
      @adapter.inject_result triplet("object-id", "attrib-name", "attrib-value")
      do_sync
      ObjectValue.first.user_id.should be_nil
    end
    
    it "should handle single quotes in attribute values" do
      # This spec is needed as the implementation manually constructs SQL strings 
      # for the inserts. 
      @adapter.inject_result triplet("not-used", "not-used", attribute_value = "'")
      do_sync
      ObjectValue.first.value.should == attribute_value
    end
    
    it "should fail gracefully if @result is missing" do
      @adapter.inject_result nil
      lambda {do_sync}.should_not raise_error
    end
    
    it "should log warning if @result is missing" do
      @adapter.inject_result nil
      Rails.logger.should_receive(:warn)
      do_sync
    end
    
    it "should not fail if limit is missing" do 
      @adapter.inject_result triplet("object-id", "atrrib", "value")
      @adapter.should_receive(:limit).and_return(nil)
      lambda {do_sync}.should_not raise_error
    end
    
    def do_sync
      @adapter.sync
    end
    
    def triplet(*args) 
      id = args.shift
      raise "Illegal triplet" unless args.size.even?
      pairs = {}
      args.each_slice(2) {|pair| pairs[pair[0]] = pair[1] }
      {id => pairs}
    end
    
    def triplets(*args) 
      args.inject({}) { |merged, triplet| merged.merge(triplet) }
    end
    
    it "should work with Fixnum id:s" do 
      pending "Feature request. Robin Spainhour"
    end
    
    it "should test triplet helper (tests spec helper method)" do
      expected_triplet = {
        "123" => {
          "name" => "value", 
          "other-name" => "other-value"
        } 
      }
      
      triplet("123", 
              "name", "value", 
              "other-name", "other-value").should == expected_triplet
    end
    
    it "should test triplets helper (tests spec helper method)" do 
      expected_triplet_hash = {
        "123" => {
          "name1" => "value1"
        },
        "456" => {
          "name2" => "value2"
        },
        "789" => {
          "name3" => "value3"
        }
      }
      
      triplets( triplet("123", "name1", "value1"),
                triplet("456", "name2", "value2"),
                triplet("789", "name3", "value3") ).should == expected_triplet_hash
    end
  end
end
