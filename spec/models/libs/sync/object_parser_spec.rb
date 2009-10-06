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
  
    it "should work with String keys" do 
      parser = parser_from(expected_object = "a-string", @valid_attributes )
      parser.objects.first.object.should == expected_object
    end 
    
    it "should convert Fixnum keys into strings" do 
      parser = parser_from(expected_object = 1234, @valid_attributes )
      parser.objects.first.object.should == expected_object.to_s
    end
    
    it "should handle single quotes in attribute values" do
      key, values = key_and_values(@valid_key, "attrib", attribute_value = "'")
      parser_from( key, values ).objects.first.value.should == attribute_value
    end
    
    it "should convert Fixnum values into strings" do 
      key, values = key_and_values(@valid_key, "attrib", attribute_value = 1234)
      parser_from( key, values ).objects.first.value.should == attribute_value.to_s
    end

    ObjectValue::RESERVED_ATTRIB_NAMES.each do |attrib_name|
      it "should not create ObjectValue for attribute named '#{attrib_name}'" do
        objects = parser_from( @valid_key, @valid_attributes.merge("#{attrib_name}" => "some-value") ).objects
        objects.size.should == 1
        {objects.first.attrib => objects.first.value}.should == @valid_attributes
      end
    end
    
    it "should set attrib_type on all ObjectValues if it is present in the triple" do 
      key, values = key_and_values(@valid_key, "firstname",   "robin", 
                                               "lastname",    "spainhour",
                                               "attrib_type", expected_type = "blob" )
      objects = parser_from( key, values ).objects
      
      objects.size.should == 2
      
      objects.each do | object | 
        object.attrib_type.should == expected_type
      end
      
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
  
  ###### Spec Helpers 
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
