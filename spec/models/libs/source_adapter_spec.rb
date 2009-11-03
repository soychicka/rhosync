require File.dirname(__FILE__) + "/../../spec_helper"
require File.dirname(__FILE__) + "/sync/sync_spec_helper"

class SourceAdapter 
  def inject_result(result) 
    @result = result
  end
end

describe SourceAdapter do 
  
  describe "sync()" do 
    before do
      @config_stubs = {:current_user => nil, :limit => nil, :id => 987 }
      
      @adapter = SourceAdapter.new
      @adapter.stub(@config_stubs)

      @injected_result = triples( triple("51", "attrib", "value"),
                                  triple("52", "attrib", "value") )
                                     
      @adapter.inject_result @injected_result
      
      # Make sure no logging is done to stdout
      @adapter.should_not_receive(:puts)
      @adapter.should_not_receive(:p)
    end

    it "should create Synchronizer instance" do 
      expect_synchronizer_init
      do_sync
    end
    
    it "should call Synchronizer.sync" do 
      synchronizer = expect_synchronizer_init
      synchronizer.should_receive(:sync).once
      do_sync
    end

    describe "when config is read from self (the adapter instance)" do 
      it "should create Synchronizer instance with limit from adapter" do 
        @adapter.should_receive(:limit).at_least(1).and_return(expected_limit = 23)
        expect_synchronizer_init(:limit => expected_limit)
        do_sync
      end
      
      it "should create Synchronizer instance with user_id from adapter" do 
        @adapter.should_receive(:current_user).and_return( mock("user", :id => (expected_user_id = 123) ) )
        expect_synchronizer_init(:user_id => expected_user_id)
        do_sync
      end
      
      it "should create Synchronizer instance with source_id from adapter" do 
        @adapter.should_receive(:id).and_return( expected_source_id = 123)
        expect_synchronizer_init(:source_id => expected_source_id)
        do_sync
      end
    end
    
    describe "when config is read from 'source' (passed to initializer)" do 
      before do 
        @source = mock("Source", @config_stubs)
        @adapter = SourceAdapter.new(@source)
        @adapter.inject_result(@injected_result)
      end
      
      it "should create Synchronizer instance with limit from source" do 
        @source.should_receive(:limit).at_least(1).and_return(expected_limit = 23)
        expect_synchronizer_init(:limit => expected_limit)
        do_sync
      end
      
      it "should create Synchronizer instance with user_id from source" do 
        @source.should_receive(:current_user).at_least(1).and_return( mock("user", :id => (expected_user_id = 123) ) )
        expect_synchronizer_init(:user_id => expected_user_id)
        do_sync
      end
        
      it "should create Synchronizer instance with source_id from source" do 
        @source.should_receive(:id).and_return( expected_source_id = 123)
        expect_synchronizer_init(:source_id => expected_source_id)
        do_sync
      end
      
    end
    
    it "should fail gracefully if @result is missing" do
      @adapter.inject_result nil
      lambda {do_sync}.should_not raise_error
    end
    
    it "should log warning if @result is missing" do
      @adapter.inject_result nil
      Rails.logger.should_receive(:warn).with(SourceAdapter::MSG_NIL_RESULT_ATTRIB)
      do_sync
    end
    
    it "should log at debug level when result is empty" do 
      @adapter.inject_result({ }) 
      Rails.logger.should_receive(:debug).with(SourceAdapter::MSG_NO_OBJECTS)
      do_sync
    end

    def do_sync
      @adapter.sync
    end
    
    def expect_synchronizer_init(options = {})
      
      data = options[:sync_data] ||= @injected_result
      source_id = options[:source_id] ||= @config_stubs[:id]
      limit = options[:limit] ||= nil
      user_id = options[:user_id] ||= nil
      
      synchronizer = Sync::Synchronizer.new( {}, @config_stubs[:id] )
      Sync::Synchronizer.should_receive(:new).with(data, source_id, limit, user_id).and_return( synchronizer )
      synchronizer
    end
    
  end
end
