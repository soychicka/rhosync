require File.dirname(__FILE__) + "/../../../spec_helper"
require File.dirname(__FILE__) + "/sync_spec_helper"
require 'sync'

describe "Sync::ObjectParser" do 
  before do 
    @valid_key = "key"
    @valid_attributes = {"attribute" => "attribute_value"}
    @valid_source_id = 1
  end
  
  describe "array_of_object_values()" do 
    
    it "should create object_value with supplied key (i.e. the object)" do
      key, values = key_and_values(expected_key = "key", "attrib", "value")
      parser = parser_from( key, values )
      parser.objects.first.object.should == expected_key
    end
    
    it "should create object_value with supplied attrib" do
      key, values = key_and_values("key", expected_attrib = "the-attribute", "value")
      parser = parser_from( key, values )
      parser.objects.first.attrib.should == expected_attrib
    end
    
    it "should create object_value with supplied value" do 
      key, values = key_and_values(expected_key = "key", "attrib", expected_value = "the-value")
      parser = parser_from( key, values )
      parser.objects.first.value.should == expected_value
    end
    
    it "should create object_value with supplied source_id" do 
      parser = parser_from( @valid_key, @valid_attributes, :source_id => (expected_source_id = 1234) )
      parser.objects.first.source_id.should == expected_source_id
    end
    
    it "should create object_value with supplied user_id" do 
      parser = parser_from( @valid_key, @valid_attributes, :user_id => (expected_user_id = 1234) )
      parser.objects.first.user_id.should == expected_user_id
    end
    
    it "should not require user_id" do
      parser = parser_from( @valid_key, @valid_attributes, :user_id => nil )
      parser.objects.first.user_id.should be_nil
    end
    
    it "should allow source_id overriding" do 
      key, values = key_and_values("key", :source_id, expected_source_id = 1234, "attrib", "value")
      parser = parser_from( key, values, :source_id => 5678 )
      parser.objects.first.source_id.should == expected_source_id
    end
    
    it "should not create an ObjectValue for an overridden source_id" do 
      key, values = key_and_values("key", "attrib", "value", :source_id, 1234)
      parser = parser_from( key, values )
      parser.objects.size.should == 1
      parser.objects.first.attrib.should == "attrib"
      parser.objects.first.value.should == "value"
    end
    
  end
  
  describe "initialize()" do
    it "should require object_key" do
      lambda { Sync::ObjectParser.new(nil, @valid_attributes, @valid_source_id) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should require object_attributes" do
      lambda { Sync::ObjectParser.new(@valid_key, nil, @valid_source_id) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should check that object_attributes is a Hash" do
      object_attribute_mock = mock("object_attributes")
      object_attribute_mock.should_receive(:is_a?).with(Hash).and_return(false)
      lambda { Sync::ObjectParser.new(@valid_key, object_attribute_mock, @valid_source_id) }.should raise_error(Sync::IllegalArgumentError)
    end
    
    it "should require source_id" do
      lambda { Sync::ObjectParser.new(@valid_key, @valid_attributes, nil) }.should raise_error(Sync::IllegalArgumentError)
    end
  end
  
  ###### Helpers 
  def parser_from(key, values, options = {})
    source_id = options[:source_id] ||= @valid_source_id
    user_id = options[:user_id] ||= nil
    Sync::ObjectParser.new(key, values, source_id, user_id)
  end
  
  def key_and_values(*args)
    one_object_triple = triple(*args)
    return one_object_triple.keys.first, one_object_triple.values.first
  end
end
