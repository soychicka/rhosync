require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ObjectValue do
  before(:each) do
    @valid_attributes = {
    }
  end

  it "should generate same id hash for known values" do
    ov = ObjectValue.create!({:attrib => 'some-attrib',
                         :object => 'some-object',
                         :value => 'some-value',
                         :source_id => 37})
    ObjectValue.find(ov.id).attrib.should == 'some-attrib'
  end
  
  
  [nil, '', 'id', 'attrib_type'].each do |invalid_value|
    it "should not allow '#{invalid_value}' as attrib value" do 
      o = ObjectValue.new(:attrib => invalid_value)
      o.valid?.should be_false
      o.errors[:attrib].should_not be_nil
    end
  end
  
  ['my_id', 'id_mine', 'my_attrib', 'attrib'].each do |value|
    it "should allow '#{value}' as attrib value" do 
      o = ObjectValue.new(:attrib => value)
      o.valid?
      o.errors[:attrib].should be_nil
    end
  end
  
  [nil, '', '   '].each do |invalid_value|
    it "should not allow '#{invalid_value}' value" do 
      o = ObjectValue.new(:value => invalid_value)
      o.valid?.should be_false
      o.errors[:value].should_not be_nil
    end
  end
end
