require File.dirname(__FILE__) + "/../../spec_helper"

describe SourceAdapter do 
  describe "sync" do 
    before do
      ObjectValue.all(&:destroy)
      @user = Factory(:user)
      
      @adapter = SourceAdapter.new
      @adapter.stub(:current_user).and_return(nil)
      @adapter.stub(:limit).and_return(nil)
      @simple_hash = triplet("object-id", "attrib-name", "attrib-value")
      
      # This is a very temporary solution while the specs are written
      # access to @result should be done with attr_reader
      @adapter.instance_eval do 
        def result=(result) 
          @result = result
        end
      end
    end
    
    describe "when source is given in initializer" do 
      it "should ask for limit from source"  
      it "should ask for current_user from source"
      it "should use source.id for for source_id value"
    end
    
    describe "when source is given in initializer is nil" do 
      it "should ask for limit from self"
      it "should ask for current_user from self"
      it "should use self.id for for source_id value"
    end
    
    it "should work with String id:s" do 
      @adapter.result = triplet(expected_object = "a-string", "name", "value")
      do_sync
      ObjectValue.first.object.should == expected_object
    end
    
    it "should ignore object_values named 'id'" do
      @adapter.result = triplet("123", "id", "ignore me")
      do_sync 
      ObjectValue.all.should be_empty
    end
    
    it "should ignore object_value where name is blank" do 
      @adapter.result = triplet("123", "", "ignore me")
      do_sync 
      ObjectValue.all.should be_empty
      
      @adapter.result = triplet("123", nil, "ignore me")
      do_sync 
      ObjectValue.all.should be_empty
    end
    
    it "should ignore object_value where value is blank" do 
      @adapter.result = triplet("123", "attrib-name", "")
      do_sync 
      ObjectValue.all.should be_empty
      
      @adapter.result = triplet("123", "attrib-name", nil)
      do_sync 
      ObjectValue.all.should be_empty
    end
    
    it "should use default source_id from @source" do 
      @adapter.result = triplet("123", "attrib-name", "value")
      @adapter.stub(:id).and_return(expected_source_id = 321)
      do_sync
      ObjectValue.first.source_id.should == expected_source_id
    end
    
    it "should override default source_id when given as object_value" do 
      pending "Cannot figure out how such a @result hash would look. Robin Spainhour"
    end
    
    it "should not insert more items than the configured limit" do 
      @adapter.result = triplet("51", "attrib", "value").merge(
                        triplet("52", "attrib", "value")).merge(
                        triplet("53", "attrib", "value")).merge(
                        triplet("54", "attrib", "value"))
                                
      @adapter.stub(:limit).and_return(expected_sync_count = 3)
      do_sync
      ObjectValue.all.size.should == expected_sync_count
    end
    
    it "should save an object value" do
      @adapter.result = @simple_hash
      do_sync
      ObjectValue.all.size.should == @simple_hash.size
    end
    
    it "should store given id as ObjectValue.object" do 
      @adapter.result = triplet(expected_object = "55", "attrib", "value")
      do_sync
      ObjectValue.first.object.should == expected_object
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
    
    
    it "should work with Fixnum id:s" do 
      pending "Feature request. Robin Spainhour"
    end
    
    it "should fail gracefully if @result is missing" do
      pending "Feature request. Robin Spainhour"
    end
    
    it "should fail gracefully if limit is missing" do 
      pending "Feature request. Robin Spainhour"
    end
    
    it "should validate the triplet helper" do
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
    
  end
  
end