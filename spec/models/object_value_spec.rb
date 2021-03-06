require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
 
describe ObjectValue do
  it "should generate same id hash for known values" do
    ov = ObjectValue.create!({:attrib => 'some-attrib',
                         :object => 'some-object',
                         :value => 'some-value',
                         :source_id => 37,
                         :update_type => 'query'})
    ObjectValue.find(ov.id).attrib.should == 'some-attrib'
  end
  
  
  [nil, '', 'id', 'attrib_type'].each do |invalid_value|
    it "should not allow '#{invalid_value}' as attrib value" do
      o = ObjectValue.new(:attrib => invalid_value, :update_type => 'query')
      o.valid?.should be_false
      o.errors[:attrib].should_not be_nil
    end
  end
  
  ['my_id', 'id_mine', 'my_attrib', 'attrib'].each do |value|
    it "should allow '#{value}' as attrib value" do
      o = ObjectValue.new(:attrib => value, :update_type => 'query')
      o.valid?
      o.errors[:attrib].should be_nil
    end
  end
  
  [nil, '', ' '].each do |invalid_value|
    it "should not allow '#{invalid_value}' value" do
      o = ObjectValue.new(:value => invalid_value, :update_type => 'query')
      o.valid?.should be_false
      o.errors[:value].should_not be_nil
    end
  end
  
  [nil, ''].each do |valid_nonquery_attrib_value|
    it "should allow nonquery '#{valid_nonquery_attrib_value}' value" do
      o = ObjectValue.new(:attrib => valid_nonquery_attrib_value,
                          :value => valid_nonquery_attrib_value,
                          :update_type => 'create')
      o.valid?
      o.errors[:value].should be_nil
    end
  end
  
  it "should validate the allowed values for attrib_type"
end
